% Lorenzo Mancini 2007951
% Homework 2 Multimedia 2023
% Stima del throughput di una connessione

% scelta server da raggiungere
server = 'atl.speedtest.clouvider.net'; % server di destinazione

command = strcat('ping -i 30 -4', " ", server);
[status, cmdout] = system(command);
serverIP = extractBetween(cmdout, '[',']'); % Indirizzo IP del server scelto
disp("server di destinazione: " + server);
disp("server IP: " + serverIP);

% calcolo numero link attraversati (TTL)
TTL = 1;
for i = 1:30 % 30 = default massimo punti di passaggio
    command = strcat('ping -i'," ", num2str(i), ' -4', " ", server); % dimensione del pacchetto non è rilevante in questo calcolo
    [status, cmdout] = system(command);
    if contains(cmdout, 'Tempo approssimativo') % successo connessione
        break;
    end
    TTL=TTL+1; % se non ho raggiunto il server aumento il TTL di 1 e ritento la connessione
end
disp("TTL netto (calcolato): " + TTL);

% confronto TTL calcolato con il valore trovato con tracert
command = strcat('tracert -4', " ", server); % comando tracert
[status, cmdout] = system(command); 
index = strfind(cmdout, " "+serverIP);
index = index - 31;
tracert_TTL = extractBetween(cmdout, index, index+5);
disp("TTL netto (tracert): " + tracert_TTL);

if TTL~=str2num(tracert_TTL{1,1})
    disp("WARNING: TTL ambiguo");
end

% numero di link (TTL) totale a/r
n=(2*TTL)-1; % considero andata e ritorno del pacchetto
disp("totale link a/r: " + n);

pkt_size = zeros(1, 10); % array contentente le varie dimensioni del pacchetto per ogni psping
RTT_min = zeros(1, length(pkt_size)); % array con il valore minimo di RTT per ogni psping
RTT_max = zeros(1, length(pkt_size)); % array con il valore massimo di RTT per ogni psping
RTT_avg = zeros(1, length(pkt_size)); % array con il valore medio di RTT per ogni psping
RTT_std = zeros(1, length(pkt_size)); % array con la deviazione standard di RTT per ogni psping
disp("array RTT min size: " + length(RTT_min));

% dimensione payload varia da 10 a 1472 bytes
% ciclo variazione di L = dimensione del pacchetto 1500 bytes
i = 1;
K = 100; % numero di pacchetti da inviare ad ogni psping
for L = 10:25:1472 % variazione della dimensione dei pacchetti
    % numero di pacchetti da inviare per ogni ping K = 100 -> '-n 100';
    command = strcat("psping -n ", num2str(K)," -i 0 -l ", num2str(L), " ", server); % esecuzione: psping -n 100 -i 0 -l 10 -4 atl.speedtest.clouvider.net
    [status, cmdout] = system(command);
    disp(command);
    %new_token = '(' + serverIP + ': )([\d]*\.[\d]*)';
    
    RTT = cellfun(@(y)(str2double(y{2})), regexp(cmdout, '(Reply from 92.119.16.139: )([\d]*\.[\d]*)', 'tokens')); % regexp tokens
    
    disp("L pkt_size: " + L + " (bytes)");

    % calcolo RTT min, max, avg, std
    RTT_min(i) = min(RTT);
    RTT_max(i) = max(RTT);
    RTT_avg(i) = mean(RTT);
    RTT_std(i) = std(RTT);

    pkt_size(i) = 8*L; % array dimensione pacchetti in bits
    i=i+1;
end

disp("FINE CONNESSIONE CON IL SERVER");

figure(1); % RTT_min
plot(pkt_size, RTT_min, "or");
grid on; 
xlabel('L (pkt size) - bits'); 
ylabel('RTT_{min}(L)');
xlim([0,12000]);
title('RTT_{min} per ' + " " + server);

figure(2); % RTT_max
plot(pkt_size, RTT_max, "om");
grid on; 
xlabel('L (pkt size) - bits'); 
ylabel('RTT_{max}(L)');
xlim([0,12000]);
title('RTT_{max} per ' + " " + server);

figure(3); % RTT_avg
plot(pkt_size, RTT_avg, "ob");
grid on; 
xlabel('L (pkt size) - bits'); 
ylabel('RTT_{avg}(L)');
xlim([0,12000]);
title('RTT_{avg} per ' + " " + server);

figure(4); % RTT_std
plot(pkt_size, RTT_std, "og");
grid on; 
xlabel('L (pkt size) - bits'); 
ylabel('RTT_{std}(L)');
xlim([0,12000]);
title('RTT_{std} per ' + " " + server);
    

% stima del coefficiente 'a'
p = polyfit(pkt_size, RTT_min, 1); % stima polinomiale
a = p(1)*0.001; % reperimento + conversione unità di misura

% stima throughput 
R = n / a; % R throughput link identici
disp("throughput R: " + R);

R_bottleneck = 2 / a; % R_bottleneck throughput bottleneck
disp("throughput R_bottleneck: " + R_bottleneck);