A = [1 0 0; 0 1 0; 0 0 1];
B = [1 -1 0 0; 0 1 -1 0; 0 0 1 -1];
C = [0 0 1; 0 1 0; 1 0 0];
D = zeros(3,4);
supply_chain = ss(A,B,C,D,1, 'TimeUnit', 'days');
supply_chain.InputName = {'Production', 'PT_{WD}', 'PT_{DR}', 'Demand'};
supply_chain.OutputName = {'Retail Inventory', 'Distribution Inventory', 'Warehouse Inventory'};
supply_chain.StateName = {'Warehouse Inventory', 'Distribution Inventory', 'Retail Inventory'};
supply_chain = setmpcsignals(supply_chain, MV=[1 2 3], MD=4, MO=[1 2 3]);
mpcsupplychain = mpc(supply_chain);

%random demand creation
demand_random = randi([300 1000],1,91);
r2_random = demand_random*5;
r3_random = demand_random*7;

reference_signal = [demand_random;r2_random;r3_random]';
% mpc parameter description

mpcsupplychain.PredictionHorizon = 10;

mpcsupplychain.ControlHorizon = 1;

mpcsupplychain.Weights.ManipulatedVariablesRate = [0,0,0];
%mpcsupplychain.Weights.OutputVariables = [1,0.2,0.2];

%manipulated variable description
 mpcsupplychain.ManipulatedVariables(1).Min = 0;
 mpcsupplychain.ManipulatedVariables(1).Max = 2000;
 mpcsupplychain.ManipulatedVariables(1).Type = 'integer';

mpcsupplychain.ManipulatedVariables(2).Min = 0;
mpcsupplychain.ManipulatedVariables(2).Max = 1500;
mpcsupplychain.ManipulatedVariables(2).Type = 'integer';

mpcsupplychain.ManipulatedVariables(3).Min = 0;
mpcsupplychain.ManipulatedVariables(3).Max = 1500;
mpcsupplychain.ManipulatedVariables(3).Type = 'integer';

%output variable description
mpcsupplychain.OutputVariables(1).Min = 0;
%mpcsupplychain.OutputVariables(1).Max = 2000;

mpcsupplychain.OutputVariables(2).Min = 0;
%mpcsupplychain.OutputVariables(2).Max = 2500;

mpcsupplychain.OutputVariables(3).Min = 0;
%mpcsupplychain.OutputVariables(3).Max = 3000;

E = [0 1 0; 0 0 1];
F = [0 0 -1; 0 -1 0];
G = [0;0];
V = [0;0];

setconstraint(mpcsupplychain,E,F,G,V)

initial_state_sim_option = mpcsimopt(mpcsupplychain);
initial_state_sim_option.PlantInitialState = [1200, 1100, 1000];

[y,t,u,xp] = sim(mpcsupplychain,91,reference_signal,demand_random',initial_state_sim_option);
plot(mpcsupplychain,t,y,reference_signal,u, demand_random');
ivr_demand_diff = y(:,1)-demand_random';
positive_indices = find(ivr_demand_diff>0);
positive_numbers = length(positive_indices);

customer_satisfaction = (y(:,1)./demand_random');
customer_satisfaction(customer_satisfaction>1) = 1;
customer_satisfaction=customer_satisfaction*100;
avg_customer_satisfaction = mean(customer_satisfaction);

figure()
subplot(3,1,1)
plot(t,y(:,1), 'color', [0 0.4470 0.7410])
hold on
plot(t,reference_signal(:,1), 'color', [0.5 0.5 0.5])
legend('Actual', 'Reference')
xlabel('Time (Days)')
ylabel('Retail Inventory')
title('Inventory Levels')
subplot(3,1,2)
plot(t,xp(:,2), 'color', [0 0.4470 0.7410]);
hold on
plot(t,reference_signal(:,2), 'color', [0.5 0.5 0.5])
legend('Actual', 'Reference')
xlabel('Time (Days)')
ylabel('Distribution Inventory')
subplot(3,1,3)
plot(t,xp(:,1), 'color', [0 0.4470 0.7410]);
hold on
plot(t,reference_signal(:,3), 'color', [0.5 0.5 0.5])
legend('Actual', 'Reference')
xlabel('Time (Days)')
ylabel('Warehouse Inventory')

figure()
plot(t, customer_satisfaction)
xlabel('Time (Days)')
ylabel('Customer Satisfaction (%)')
ylim([0 105])
title('Customer Satisfaction Rate')