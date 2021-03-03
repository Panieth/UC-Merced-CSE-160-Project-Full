from TestSim import TestSim

def main():
    # Get simulation ready to run.
    s = TestSim();

    # Before we do anything, lets simulate the network off.
    s.runTime(1);

    # Load the the layout of the network.
    s.loadTopo("long_line.topo");

    # Add a noise model to all of the motes.
    s.loadNoise("no_noise.txt");

    # Turn on all of the sensors.
    s.bootAll();

    # Add the main channels. These channels are declared in includes/channels.h
    s.addChannel(s.COMMAND_CHANNEL);
    s.addChannel(s.GENERAL_CHANNEL);

    # Add the channels necessary for project 1
    s.addChannel(s.FLOODING_CHANNEL);  #channel for the flooding implementation
    s.addChannel(s.NEIGHBOR_CHANNEL);  #channel for the neighbor discovery implementation


    # After sending a ping, simulate a little to prevent collision.
    s.runTime(1);
    #s.ping(2, 5, "Hello, World");
    s.moteOff(4);
    s.runTime(10);

    #s.neighborDMP(2);
    #s.runTime(10);

    #s.ping(1, 10, "Hi!");
    s.runTime(10);

    s.ping(1, 8, "Please work");
    s.runTime(20);

if __name__ == '__main__':
    main()
