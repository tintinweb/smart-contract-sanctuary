/**
 * Ether sheet music
 */

pragma solidity ^0.4.21;


/**
 * Ownable contract base
 */

contract OwnableContract {

    address private owner;

    function OwnableContract() public {

        owner = msg.sender;

    }

    modifier onlyOwner() {

        require( msg.sender == owner );
        _;

    }

    function getOwner() public view returns ( address ) {

        return owner;

    }

    function changeOwner( address newOwner ) onlyOwner public {

        owner = newOwner;

    }
}


/**
 * Main sheet music contract
 */

contract SheetMusic is OwnableContract {

    /**
     * Note lengths
     */

    enum NoteLength {

        WHOLE_NOTE,

        DOTTED_HALF_NOTE,

        HALF_NOTE,

        DOTTED_QUARTER_NOTE,

        QUARTER_NOTE,

        DOTTED_EIGHTH_NOTE,

        EIGHTH_NOTE,

        DOTTED_SIXTEENTH_NOTE,

        SIXTEENTH_NOTE

    }


    /**
     * Note struct
     */

    struct Beat {

        address maker;

        uint8[] midiNotes;

        NoteLength length;

        uint donation; //In weis

    }


    /**
     * Internal props
     */

    mapping( uint => Beat ) private notes;

    uint private numNotes;

    address private donatee;


    //Values donated toward goal and milestone

    uint private totalValue;

    uint private milestoneValue;


    //Goals

    uint constant DONATION_GOAL = 100 ether;

    uint private minDonation = 0.005 ether;


    //Transfer after a certain amount

    uint private milestoneGoal = 5 ether;


    //Full donation goal met

    bool private donationMet = false;


    /**
     * Midi requirements
     */

    uint8 constant MIDI_LOWEST_NOTE = 21;

    uint8 constant MIDI_HIGHEST_NOTE = 108;


    /**
     * Events
     */

    event NoteCreated( address indexed maker, uint id, uint donation );

    event DonationCreated( address indexed maker, uint donation );

    event DonationTransfered( address donatee, uint value );

    event DonationGoalReached( address MrCool );

    event MilestoneMet( address donater );


    /**
     * Construct
     */

    function SheetMusic( address donateeArg ) public {

        donatee = donateeArg;

    }


    /**
     * Main create note
     * There is no 0 note. First one is 1
     */

    function createBeat( uint8[] midiNotes, NoteLength length ) external payable {

        totalValue += msg.value;
        milestoneValue += msg.value;


        //Check note min value

        require( msg.value >= minDonation );


        //Check valid notes

        checkMidiNotesValue( midiNotes );


        //Create note

        Beat memory newBeat = Beat({
            maker: msg.sender,
            donation: msg.value,
            midiNotes: midiNotes,
            length: length
        });

        notes[ ++ numNotes ] = newBeat;

        emit NoteCreated( msg.sender, numNotes, msg.value );

        checkGoal( msg.sender );

    }


    /**
     * Create passage or number of beats
     * Nested array unimplemented right now
     */

    function createPassage( uint8[] userNotes, uint[] userDivider, NoteLength[] lengths )
        external
        payable
    {

        //Add values regardless if valid

        totalValue += msg.value;
        milestoneValue += msg.value;

        uint userNumberBeats = userDivider.length;
        uint userNumberLength = lengths.length;


        //Check note min value and lengths equal eachother
        //Check valid midi notes

        require( userNumberBeats == userNumberLength );

        require( msg.value >= ( minDonation * userNumberBeats ) );

        checkMidiNotesValue( userNotes );


        //Create beats

        uint noteDonation = msg.value / userNumberBeats;
        uint lastDivider = 0;

        for( uint i = 0; i < userNumberBeats; ++ i ) {

            uint divide = userDivider[ i ];
            NoteLength length = lengths[ i ];

            uint8[] memory midiNotes = splice( userNotes, lastDivider, divide );

            Beat memory newBeat = Beat({
                maker: msg.sender,
                donation: noteDonation,
                midiNotes: midiNotes,
                length: length
            });

            lastDivider = divide;

            notes[ ++ numNotes ] = newBeat;

            emit NoteCreated( msg.sender, numNotes, noteDonation );

        }

        checkGoal( msg.sender );

    }


    /**
     * Random value add to contract
     */

    function () external payable {

        totalValue += msg.value;
        milestoneValue += msg.value;

        checkGoal( msg.sender );

    }


    /**
     * Donate with intent
     */

    function donate() external payable {

        totalValue += msg.value;
        milestoneValue += msg.value;

        emit DonationCreated( msg.sender, msg.value );

        checkGoal( msg.sender );

    }


    /**
     * Check if goal reached
     */

    function checkGoal( address maker ) internal {

        if( totalValue >= DONATION_GOAL && ! donationMet ) {

            donationMet = true;

            emit DonationGoalReached( maker );

        }

        if( milestoneValue >= milestoneGoal ) {

            transferMilestone();
            milestoneValue = 0;

        }

    }


    /**
     * Getters for notes
     */

    function getNumberOfBeats() external view returns ( uint ) {

        return numNotes;

    }

    function getBeat( uint id ) external view returns (
        address,
        uint8[],
        NoteLength,
        uint
    ) {

        Beat storage beat = notes[ id ];

        return (
            beat.maker,
            beat.midiNotes,
            beat.length,
            beat.donation
        );

    }


    /**
     * Stats getter
     */

    function getDonationStats() external view returns (
        uint goal,
        uint minimum,
        uint currentValue,
        uint milestoneAmount,
        address donateeAddr
    ) {

        return (
            DONATION_GOAL,
            minDonation,
            totalValue,
            milestoneGoal,
            donatee
        );

    }

    function getTotalDonated() external view returns( uint ) {

        return totalValue;

    }

    function getDonatee() external view returns( address ) {

        return donatee;

    }


    /**
     * Finishers
     */

    function transferMilestone() internal {

        uint balance = address( this ).balance;

        donatee.transfer( balance );

        emit DonationTransfered( donatee, balance );

    }


    /**
     * Internal checks and requires for valid notes
     */

    function checkMidiNoteValue( uint8 midi ) pure internal {

        require( midi >= MIDI_LOWEST_NOTE && midi <= MIDI_HIGHEST_NOTE );

    }

    function checkMidiNotesValue( uint8[] midis ) pure internal {

        uint num = midis.length;

        //require less or equal to all notes allowed

        require( num <= ( MIDI_HIGHEST_NOTE - MIDI_LOWEST_NOTE ) );

        for( uint i = 0; i < num; ++ i ) {

            checkMidiNoteValue( midis[ i ] );

        }

    }


    /**
     * Owner setters for future proofing
     */

    function setMinDonation( uint newMin ) onlyOwner external {

        minDonation = newMin;

    }

    function setMilestone( uint newMile ) onlyOwner external {

        milestoneGoal = newMile;

    }


    /**
     * Array splice function
     */

    function splice( uint8[] arr, uint index, uint to )
        pure
        internal
        returns( uint8[] )
    {

        uint8[] memory output = new uint8[]( to - index );
        uint counter = 0;

        for( uint i = index; i < to; ++ i ) {

            output[ counter ] = arr[ i ];

            ++ counter;

        }

        return output;

    }

}