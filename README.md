# Factor-I/O
Adds several sensors which allow for automatic monitoring of things not normally available to the circuit network, thus enabling more advanced automation.
-----------------

## Actuators

Place these with their "back" (the side away from where the red and green wires attach) facing into the object to actuate.

* Belt Rotation Actuator: Place this facing into a belt. Give this the letter signals N/S/E/W to change the belt direction.
* Inserter/Loader Filter Actuator: Place this facing into a filter inserter. Give it an item filter to set the inserter's filter. Only works with 1 item, nondeterministic if there's more than 1 item being sent to it. (Mostly replaced by the "set filters" mode on a filter inserter.)

## Independent Detectors

These can be placed anywhere and will output their information.

* Time of Day detector: Output time ranging from 0 to 24,000.
* Research Progress detector: Output research progress from 0 to 100
* Timing Detector: Toggles between either 0/30 or 15/45 once a second. (I believe this is a glitch, but you could still detect >= 30 for both.)
* Train Status Detector: Detects the status of all trains on your force, and reports how many are moving, stopped at station, stopped at a rail signal, and stuck because "no path".

## Linked Detectors

These operate on "linking" to another entity by directly connecting them with red/green wire (i.e. not over power poles). They can only ever be linked to one entity at a time. If you break that link, they'll try and relink with something else.

* Construction Bot Count Detector: Link to a roboport or logi-chest to output total construction bots of the network. (Equivalent to "T" in the read robot statistics.)
* Logistics Bot Count Detector: Link to a roboport or logi-chest to output total construction bots of the network. (Equivalent to "Y" in the read robot statistics.)
* Free Inventory Slots detector: Link with a chest to output the number of open inventory slots.
* Fluid Temperature Detector: Link with a tank to output its temperature.
* Power Consumption Detector: Link with a power pole to output consumption, in KW (i.e. 3MW outputs -3,000)
* Power Consumption Detector: Link with a power pole to output production, in KW (i.e. 3MW outputs -3,000)
* Power Grid Satisfaction Detector: Link with an accumulator to output accumulator charge. (Equivalent to "A" in the accumulator)
* Train Fill Level Detector: Link with a station (w/ a stopped train) to output the number of fully filled wagons, and the number of fully empty wagons.
* Train Car Count Detector: Link with a station (w/ a stopped train) to output the number of forward facing locomotives, backwards facing locomotives, cargo wagons, and fluid wagons
* Train Total Contents Detector: Link with a station (w/ a stopped train) to output the sum of all cargo, and the sum of all liquids.
