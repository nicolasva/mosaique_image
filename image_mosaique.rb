#!/usr/bin/ruby
require 'RMagick'
require 'tk'
require 'fileutils'

class Mosaique
	def supprime_fichier_temp_regex(rep, regex)
		Dir.entries(rep).each do |nom_fichier|
			chemin = File.join(rep, nom_fichier)
		   	if (regex.match(nom_fichier))
			   	   type_fic = File.directory?(chemin) ? Dir : File
			   	begin
				   type_fic.delete(chemin)
			   	end
		   	end
		end
	end

	def select_img_reference
	      @img_reference = @mybutton.getOpenFile
	      lect_img_reference
	end

	def lect_img_reference
		@mylabel.configure('text' => "Voici votre image de référence : "+@img_reference)
	end
	
	def register_files_tab(files_register)
		if files_register != ""
			@tab_register_files.push(files_register)
			files_register = "Dernier fichier selectionné : " + files_register
		else
			files_register = "Veuillez selectionner une image pour pouvoir la mettre"
		end
			@mylabel.configure("text" => files_register)
			if @img_reference != "" && @tab_register_files.length > 0
				@mybutton_exit.configure("text" => "Exécuter le programme")
				@mybutton_exit.command { traitement_vignette_origine }
				@mybutton_exit.place('height'	=> 25,
					     	     'width'	=> 280,
						     'x'	=> 0,
						     'y'	=> 200)	     
			else
				@mybutton_exit.configure("text" => "lire l'ensemble des vignettes enregistrés")
		        	@mybutton_exit.command { lect_files_register }
				@mybutton_exit.place('height'	=> 25,
			     			     'width'	=> 280,
			     			     'x'	=> 0,
			     			     'y'	=> 200)
			end
	end

	def lect_files_register
		@file_register = "Liste des images vignettes enregistrés : \n"
		@tab_register_files.length.times do |i|
			@file_register += @tab_register_files[i]+"\n"
		end
		  @mylabel.configure('text' => @file_register)
	end

	def button_click
		@files = @mybutton.getOpenFile
		register_files_tab(@files)
	end

	def admin_menu	
		Tk.messageBox(
		  'type'	=> "ok",
		  'icon'	=> "info",
		  'title'	=> "Title",
		  'message'	=> "Message"
	 	)
	end

	def traitement_vignette_origine	
		buttons = Magick::ImageList.new
		j = 0
		ligne = 0
		colonne = 0

		tab_image_vignette_original = []
		tab_image_decoupe_original = []
		for compteur in (0..@tab_register_files.length-1)
      			img = Magick::Image.read("#{@tab_register_files[compteur]}").first
      			img.write("#{@tab_register_files[compteur]}.gif")
      			largeur, hauteur = 50, 50
      			vignette = img.resize(largeur, hauteur)
      			vignette.write("register_img_vignette/mignature_#{compteur}.gif")
      			vignette.scale! 0.5
      			tab_image_vignette_original += ["register_img_vignette/mignature_#{compteur}.gif"] 
		end

		imagelist = Magick::ImageList.new
		img = Magick::Image.read(@img_reference).first
		largeur, hauteur = 350,350
		image_redimensionne = img.resize(largeur, hauteur)
		image_redimensionne.write("img_redimensionne/image_redimensionne.jpg")
			49.times do
				if ligne == 250
	   			    ligne = 0
				    colonne += 50
	     				if colonne >= 250
	        				colonne = 0
	     				end
				end
		chopped = image_redimensionne.crop(ligne,colonne,31,31)
		#puts "dfdfds"
		bg = Magick::Image.new(image_redimensionne.columns, image_redimensionne.rows)
		bg = bg.composite(chopped, 0, 0, Magick::OverCompositeOp)
		bg = bg.crop(0,0,50,50,true)
		bg.write("image_decompose_vignette/chop_after_#{ligne.to_s}_#{colonne.to_s}.gif")
		tab_image_decoupe_original += ["image_decompose_vignette/chop_after_#{ligne.to_s}_#{colonne.to_s}.gif"]
		ligne += 50
		end

		for compteur_image_original in (0..tab_image_decoupe_original.length-1)
	   		image_1 = Magick::Image.read(tab_image_decoupe_original[compteur_image_original]).first
		    for compteur_image_vignette in (0..tab_image_vignette_original.length-1) 
	   		image_2 = Magick::Image.read(tab_image_vignette_original[compteur_image_vignette]).first 
	   		result_couleur_channel = image_1.compare_channel(image_2, Magick::MeanAbsoluteErrorMetric) 
	   	puts result_couleur_channel[1]	
			if result_couleur_channel[1] < 120
				tab_image_vignette_original.delete compteur_image_vignette
	       			buttons << image_2
	       			#puts buttons			
	   		end
		   end
		end

		# Create a image that will hold the image (GIF) in 5 rows and 5 columns
		l = c = 0
		cells = Magick::ImageList.new
		cells.new_image buttons.columns*7, buttons.rows*7 do	
			self.background_color = "#000000ff" 
		end
		cells.matte = true
		offset = Magick::Rectangle.new(0,0,0,0)
		tab_image_decoupe_original.length.times { |i|	
			if l == 7
				l = 0
				c += 1
			end
		button = buttons[i]
		offset.x = c*button.columns
		offset.y = l*button.rows
		button.page = offset
		button.matte = true
		cells << button
 		l += 1
		}

		#puts "Construction de la mosaique en cours, veuillez patienter etc..."
		cells.delay = 100
		cells.iterations = 10000
		res = cells.coalesce
		res.write "coalesce_anim.gif"
		res[tab_image_decoupe_original.length].write "coalesce.gif"

		supprime_fichier_temp_regex("image_decompose_vignette", /^.{1,}\.(.{1,})$/)
		supprime_fichier_temp_regex("register_img_vignette_redimensionne", /^.{1,}\.(.{1,})$/)
		supprime_fichier_temp_regex("img_redimensionne", /^.{1,}\.(.{1,})$/)
	end

	def initialize
	@img_reference = ""
	@file_register = "" 
	@tab_register_files = []
	fenetre = TkRoot.new { title 'essaie programme perso' }
	menu_spec = [
			     [
			       ["Image d'origine"],
			       ["Selectionner une image d'origine", lambda { select_img_reference } ],
			       ["Uploader les images vignettes", lambda { button_click } ],
			       ["Lire les vignettes", lambda { lect_files_register } ],
			       ["Lire l'image de référence", lambda { lect_img_reference } ],
			       ["Enregistrer les images", lambda { register_new_images } ],
			       ["traiter les images", lambda { traitement_vignette_origine }],
			       ["Sortir", lambda { exit } ]
			      ]
		     ]
	
	@menubar = TkMenubar.new(fenetre, menu_spec, 'tearoff' => false)
	@menubar.pack('fill'=>'x', 'side'=>'top')
	@label = TkLabel.new(fenetre)
	@label.text = "Selectionner une image pour l'uploader : "
	@label.place('height'	=> 25, 
		     'width'	=> 258,
		     'x'	=> 10,
		     'y'	=> 60)
	@mybutton = TkButton.new(fenetre)
	@mybutton.text = "Uploader une image vignette"
	@mybutton.place('height' => 25,
		     'width'	=> 203,
		     'x'	=> 300,
		     'y'	=> 60)
	@mybutton.command { button_click }
       	@mybuttonregister = TkButton.new(fenetre)
	@mybuttonregister.text = "Uploader une image de comparaison"
	@mybuttonregister.place('height'	=> 25,
				'width'		=> 250,
				'x'		=> 10,
				'y'		=> 120)
	@mybuttonregister.command { select_img_reference }
	@myfont = TkFont.new('size' => 10, 'weight' => 'bold')
	@mylabel = TkLabel.new(fenetre)
	@mylabel.configure('text' => "", 'font' => @myfont)
	@mylabel.pack('padx' => 0, 'pady' => 10)
	@mybutton_exit = TkButton.new(fenetre)
	@mybutton_exit.text = "sortir du programme"
	@mybutton_exit.place('height'	=> 25,
			     'width'	=> 153,
			     'x'	=> 0,
			     'y'	=> 200)
	@mybutton_exit.command { exit  }
	Tk.mainloop
	end
end

Mosaique.new
