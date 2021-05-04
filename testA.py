from TestSim import TestSim

def main():
    # Get simulation ready to run.
    s = TestSim();

    # Before we do anything, lets simulate the network off.
    s.runTime(1);

    # Load the the layout of the network.
    s.loadTopo("pizza.topo");      #s.loadTopo("tuna-melt.topo"); 

    # Add a noise model to all of the motes.
    s.loadNoise("no_noise.txt");

    # Turn on all of the sensors.
    s.bootAll();

    # Add the main channels. These channels are declared in includes/channels.h
    s.addChannel(s.COMMAND_CHANNEL);
    s.addChannel(s.GENERAL_CHANNEL);
    s.addChannel(s.TRANSPORT_CHANNEL);

    # define ports and motes
    goodMote = 1;
    goodPort = 42;
    otherGoodMote = 7;
    otherGoodPort = 99;

    s.runTime(300);
    
    

    

    s.testClient(4, 15, goodMote, goodPort, 150);
    s.runTime(1);
    s.runTime(150);

    s.testServer(otherGoodMote, otherGoodPort);

    s.runTime(60);





if __name__ == '__main__':
    main()
