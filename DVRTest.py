# a file to implement the testing of DVR component for project 2

def main():

  main():
    # Get simulation ready to run.
    s = TestSim()

    # Before we do anything, lets simulate the network off.
    s.runTime(1)

    # Load the the layout of the network.
    s.loadTopo("DVR.topo")

    # Add a noise model to all of the motes.
    s.loadNoise("no_noise.txt")

    # Turn on all of the sensors.
    s.bootAll()

    # Add the main channels. Comment out the ones not desired
    s.addChannel(s.COMMAND_CHANNEL)
    s.addChannel(s.GENERAL_CHANNEL)
    #s.addChannel(s.HASHMAP_CHANNEL)
    #s.addChannel(s.FLOODING_CHANNEL)
    #s.addChannel(s.NEIGHBOR_CHANNEL)
    s.addChannel(s.ROUTING_CHANNEL)   

    # After sending a ping, simulate a little to prevent collision.
    s.runTime(50)

    s.routeDMP(1)
    s.runTime(10)

    s.routeDMP(2)
    s.runTime(10)

    s.routeDMP(3)
    s.runTime(10)

    s.routeDMP(9)
    s.runTime(10)

    s.ping(1, 8, "Hello")
    s.runTime(10)

    s.ping(2, 7, "Work pls")
    s.runTime(20)

    #s.printMessage(3, "Mote 3 signing off...")
    #s.runTime(5)

    #s.moteOff(3)
    #s.runTime(40)

    #s.ping(2, 4, "Still works?")
    #s.runTime(20)

    #s.routeDMP(2)
    #s.runTime(20)

    #s.routeDMP(4)
    #s.runTime(20)

    #s.routeDMP(5)
    #s.runTime(20)
if __name__ == '__main__':
    main()

    