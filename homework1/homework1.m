% Lorenzo Mancini 2007951
% Homework Multimedia 2023
% Codifica d'immagini basata sulla DCT

%1. Caricare un'immagine a colori RGB  in formato BMP e/o JPG e/o PGM (uno dei tre formati è sufficiente)
fileName = 'colors.bmp';
image = imread(fileName); % caricamento immagine

%figure(1); imshow(image); title("Immagine in RGB"); axis image; axis off;  % visualizzazione immagine nelle coordinate RGB

%2. Effettuare il cambio di spazio dei colori da RGB a YCbCr
YCBCR= rgb2ycbcr(image);
y = YCBCR(:,:,1);
cb = YCBCR(:,:,2);
cr = YCBCR(:,:,3);

%figure(2); imshow(YCBCR); title("Immagine in YCBCR"); % visualizzazione immagine nelle coordinate YCBCR

x_r = 10:10:100; % array asse x [R] per tutti i grafici
y_psnr = []; % array asse y [PSNR] per grafici con curve singole
y_n_psnr = []; % array asse y [PSNR, N] per grafico con curve a confronto

%3 Per ognuna delle componenti Y, Cb e Cr, dato un numero R tra 1 e 100:
%3.1 Effettua la DCT bidimensionale con blocchi di dimensione parametrizzabile N della componente
for i = 1:3
    if i == 1
        log2blockSize = 3; % N = 2^3 = 8
    elseif i == 2
        log2blockSize = 4; % N = 2^4 = 16
    elseif i == 3
        log2blockSize = 6; % N = 2^6 = 64
    end

    blockSize = 2^log2blockSize; % dimensione N dei blocchi
    dctfun = @(block_struct) dct2(block_struct.data); % definizione DCT

    % codifica di ciascuna componente
    y_dct = blockproc(y, [blockSize blockSize], dctfun);
    cb_dct = blockproc(cb, [blockSize blockSize], dctfun);
    cr_dct = blockproc(cr, [blockSize blockSize], dctfun);

    %3.2 Mette a zero una frazione pari a R% dei coefficienti DCT dell'intera componente, e più precisamente quelli con valore assoluto più piccolo di un'opportuna soglia
    for R = 10 : 10 : 100
        threshold = prctile(abs(y_dct(:)), R); % definizione soglia (threshold)
        y_dct(abs(y_dct) <= threshold) = 0; % azzeramento percentuale componente y
        
        threshold = prctile(abs(cb_dct(:)), R); % definizione soglia (threshold)
        cb_dct(abs(cb_dct) <= threshold) = 0; % azzeramento percentuale componente cb
        
        threshold = prctile(abs(cr_dct(:)), R); % definizione soglia (threshold)
        cr_dct(abs(cr_dct) <= threshold) = 0; % azzeramento percentuale componente cr
        
        %3.3 Effettua la DCT inversa sui blocchi dopo sogliaggio, ottenendo la versione "compressa" della componente
        idctfun = @(block_struct) idct2( double(block_struct.data) ); % definizione IDCT

        % decodifica di ciascuna componente
        y_idct = uint8(blockproc(y_dct,[blockSize blockSize], idctfun));
        cb_idct = uint8(blockproc(cb_dct,[blockSize blockSize], idctfun));
        cr_idct = uint8(blockproc(cr_dct,[blockSize blockSize], idctfun));
        
        %3.4 Calcola l'MSE tra la componente originale e la componente "compressa"
        MSE_Y = mean((y(:)-y_idct(:)).^2);
        MSE_Cb = mean((cb(:)-cb_idct(:)).^2);
        MSE_Cr = mean((cr(:)-cr_idct(:)).^2);
        
        %4 Calcola l'MSE pesato: MSE_P = 3/4 MSE_Y + 1/8 MSE_Cb + 1/8 MSE_Cr
        MSE_P = 3/4*MSE_Y + 1/8*MSE_Cb + 1/8*MSE_Cr;
        
        %5 Calcola il PSNR pesato come 10log_10 (255^2/MSE_P)
        PSNR = 10*log10((255^2)/MSE_P);

        y_psnr(R/10)= PSNR; % riempimento array per grafico di curva singola
        y_n_psnr(R/10,i) = y_psnr(R/10); % riempimento array per grafico delle curve a confronto

    end

    %6 Ripete i passi da 3 a 5 per diversi valori di R: da 10 a 100 a passi di 10

    %7 Traccia la curva del PSNR in funzione di R
    figure(i);
    plot(x_r, y_psnr); % grafico curva singola, il secondo argomento della funzione plot() è un array
    grid on;
    title(sprintf('Tasso distorsione per N = %2d', blockSize)); 
    xlabel('R'); 
    ylabel('PSNR(dB)');
    xlim([10,100]); 
    xticks(10 : 10 : 100)

end

%stampa del grafico delle curve a confronto
figure(4);
plot(x_r, y_n_psnr); % il secondo argomento della funzione plot() deve essere una matrice per poter disegnare più curve differenti
grid on;
title(sprintf('Risultati a confronto'));
xlabel('R'); 
ylabel('PSNR(dB)');
xlim([10,100]); 
xticks(10 : 10 : 100)
legend({"N = 8", "N = 16", "N = 64"},"Location","northeastoutside")
