pixels_x = 200;
pixels_y = 200;

image_name1= 'image_0179.txt';
confocal_image = flipud(import_200by200confocalscan(image_name1));
figure; imagesc(confocal_image)
xlabel('Confocal X pixels')
ylabel('Confocal Y pixels')
title(image_name1,'Interpreter','none')
colorr = colorbar;
colormap(jet);
ylabel(colorr, 'PL (k counts/s)')

set(gcf, 'color', 'w')
set(gca, 'fontsize', 20)

image_name2= 'image_0180.txt';
confocal_image = flipud(import_200by200confocalscan(image_name2));
figure; imagesc(confocal_image)
xlabel('Confocal X pixels')
ylabel('Confocal Y pixels')
title(image_name2,'Interpreter','none')
colorr = colorbar;
colormap(jet);
ylabel(colorr, 'PL (k counts/s)')

set(gcf, 'color', 'w')
set(gca, 'fontsize', 20)

%%
A=importfile_X(image_name1);
MinX= A(1);
MaxX= A(2);
A=importfile_Y(image_name1);
MinY= A(1);
MaxY= A(2);


nm_per_pixel_y = 1000*(MaxY - MinY)/pixels_y;
nm_per_pixel_x = 1000*(MaxX - MinX)/pixels_x;

confocal_image1 = flipud(import_200by200confocalscan(image_name1));
confocal_image2 = flipud(import_200by200confocalscan(image_name2));

[abc,def] = dftregistration(fft2(confocal_image1), fft2(confocal_image2), 20); 
drift_tip_x = nm_per_pixel_x*abc(4)
drift_tip_y = nm_per_pixel_y*abc(3)