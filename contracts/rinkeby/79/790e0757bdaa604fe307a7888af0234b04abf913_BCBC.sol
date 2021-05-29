/**
 *Submitted for verification at Etherscan.io on 2021-05-28
*/

///@notice: attempting to use most recent 
///@concept: let users create a workout
//https://cryptomarketpool.com/deploy-a-smart-contract-to-the-polygon-network/
//
// pragma solidity ^0.8.4;
//.8.4 failed to compile because of a glitch with payable
pragma solidity ^0.5.0;

///@dev creating the first contract, capable of 
contract BCBC {
    //contract begins with allocating memory and variables
    //keep track of all created workouts
    //strings in an array, filled in when constructing contract
    string public challengeWords;
    //constructor function will assign me(msg.sender) to this var
    address public coach;
    
    //store videos
    //map the index (videocount) of the workout struct
    //keep track of how many videos (for looping?)
    uint public workoutCount = 0; //used as index for workouts
    //keep track of the _____ as a map of Workout structs
    mapping(uint => Workout) public workouts;
    
    //struct of video Data
    struct Workout {
        uint id;  //index based on current videoCount
        uint tipAmount; //keep track of total money tipped to creator for this workout
        string hash; //stringy hash
        string title; //of course we need a non-empty title
        string description; //why not?
        address payable creator;
        //group types together to save on gas
        // uint8 validateCounter; //how many checks
        // uint8 killCounter; //how many [X] not valid!
        // //to prevent double voting, we need to keep track of who has validated
        // mapping(address => bool) addressVoted; //mapping to let us check/switch on vote
        // //i think might not need to to pass in any values; mappings' default to infinite keys and "false" 
    }
    
    //honestly not sure if the event needs to have all the exact parts of a Workout...
    //notice: the () not {} and , not ; 
    event WorkoutCreated(
        uint id,  //index based on current videoCount
        uint tipAmount, //keep track of total money tipped to creator for this workout
        string hash, //stringy hash
        string title, //of course we need a non-empty title
        string description, //why not?
        address payable creator //, dont forget 
        //group types together to save on gas
        // uint8 validateCounter, //how many checks
        // uint8 killCounter, //how many [X] not valid!
        // //to prevent double voting, we need to keep track of who has validated
        // mapping(address => bool) addressVoted //mapping to let us check/switch on vote
    );
    
    //this is also an emitable event, for when its tipped
    event WorkoutTipped(
        uint id,  
        uint tipAmount,
        string hash, 
        string title, 
        string description, 
        address payable creator //,
        // uint8 validateCounter,
        // uint8 killCounter, 
        // mapping(address => bool) addressVoted
        //again not too sure why we need to emit all this stuff...
    );
    
    //day2, realized i forgot a constructor function to create the challenge words string
    constructor (string memory _challengeWords) public {
        coach = msg.sender;
        challengeWords = _challengeWords;
    }
    
    
    ///@dev possibly unnecessary?
    //mapping of killed workouts (MVP lets say recieving 3 X votes)
    // mapping(uint => bool) workoutIsKilled; //bool defaults to false, on 3 votes change this to true
    //write a modifier function for onlyAlive?  maybe later...probably not neccessary
    
    //must pass in _videoHash from IPFS and the workout title, description
    function uploadWorkout(string memory _videoHash, string memory _title, string memory _description) public payable {
        // Make sure the video hash exists
        //"validate the hash"
        require(bytes(_videoHash).length > 0);
        // Make sure workout title exists
        require(bytes(_title).length > 0);
        // Make sure workout description exists
        require(bytes(_description).length > 0);
        // Make sure uploader address exists
        //double check this one in my mocha testing
        require(msg.sender!=address(0));
    
        //after requirements do the "upload" thing
        //the first mapping of workouts is one Workout datastructure
        // Increment workout id/index
        workoutCount ++;
        //i'm not sure if this should be before or after adding the video...
    
        // Add workoutVideo hash to the contract
        //to create a new Workout, be 100% to pass in the parameters in the exactly right order
        //see line 21
        //didn't pass in anything for the mapping
        workouts[workoutCount] = Workout(workoutCount, 0, _videoHash, _title, _description, msg.sender);//, 0, 0)
        // Trigger an event (emitting with exactly the same values as above)
        emit WorkoutCreated(workoutCount, 0, _videoHash, _title, _description, msg.sender);//, 0, 0);
    }

    //tip images of valid workout id
    //this function will a .send() transaction with ETH value
    function tipWorkoutCreator(uint _id) public payable {
      //make sure id is valid (it cant be 0 or more than the total workouts)
      require(_id > 0 && _id <= workoutCount);
      //fetch & read workout, its in memory locally
      Workout memory _workout = workouts[_id];
      //find the author/creator and set it 
      address payable _creator = _workout.creator;
      //transfer to the owner of the workouot!
      // _author.transfer(1 wei);
      //don't hard code it lets just send in how much they sent
      _creator.transfer(msg.value);

      // increase that workouts' tip amount (OTC!)
      _workout.tipAmount = _workout.tipAmount + (msg.value);

    
      //update the workout (back in the mapping)
      workouts[_id] = _workout;

      //emit the event 
        // Trigger an event (emitting with exactly the same values as above)
        // emit WorkoutCreated(workoutCount, 0, _videoHash, _title, _description, msg.sender, 0, 0);
        // emit WorkoutTipped(workoutCount, 0, _videoHash, _title, _description, msg.sender, 0, 0);
      emit WorkoutTipped(
          _id, 
          _workout.tipAmount, 
          _workout.hash, 
          _workout.title, 
          _workout.description, 
          _creator);
     //    emit ImageTipped(_image.hash, _image.description, _id, _image.tipAmount, _author);

    }
    
    // /@notice return all of the created PortfolioProjects at once
    function getChallengeWords() public view returns (string memory) {
        return challengeWords;
    }
    
    
    //thats it for the MVP of bcbc i think.
}