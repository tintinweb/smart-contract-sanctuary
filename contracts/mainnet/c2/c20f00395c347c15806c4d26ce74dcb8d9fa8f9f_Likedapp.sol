pragma solidity ^0.4.2;

contract Likedapp{

    //state variables

    //like options: 1 - I love you-heart!, 2 - like-smile, 3 - youre cool-glasses, 4 - ok-regular, 5 -I dislike-angry you, 0 - welcome :)

    //Model Raction
    struct Reactions{
        int8 action;
        string message;
    }

    //Model User
    struct User {
        uint id;
        uint userReactionCount;
        address user_address;
        string username;
        Reactions[] reactions;
    }

    //Store User
    User[] userStore;

    //Fetch User
    //TO:do we need id or address to reference user
    mapping(address => User) public users;
    //Store User Count
    uint public userCount;

    //message price
    uint price = 0.00015 ether;

    //my own
    address public iown;

    //event declaration
    event UserCreated(uint indexed id);
    event SentReaction(address user_address);

    //Constructor
    constructor() public{
        iown = msg.sender;
    }

    function addUser(string _username) public {

        //check string length
        require(bytes(_username).length > 1);

        //TO DO: Check if username exist
        require(users[msg.sender].id == 0);

        userCount++;
        userStore.length++;
        User storage u = userStore[userStore.length - 1];
        Reactions memory react = Reactions(0, "Welcome to LikeDapp! :D");
        u.reactions.push(react);
        u.id = userCount;
        u.user_address = msg.sender;
        u.username = _username;
        u.userReactionCount++;
        users[msg.sender] = u;

        //UserCreated(userCount);
    }


    function getUserReaction(uint _i) external view returns (int8,string){
        require(_i >= 0);
        return (users[msg.sender].reactions[_i].action, users[msg.sender].reactions[_i].message);
    }

    function sendReaction(address _a, int8 _l, string _m) public payable {
         require(_l >= 1 && _l <= 5);
         require(users[_a].id > 0);

        if(bytes(_m).length >= 1){
            buyMessage();
        }

        users[_a].reactions.push(Reactions(_l, _m));
        users[_a].userReactionCount++;

        //SentReaction(_a);
    }

    function getUserCount() external view returns (uint){
        return userCount;
    }

    function getUsername() external view returns (string){
        return users[msg.sender].username;
    }

    function getUserReactionCount() external view returns (uint){
        return users[msg.sender].userReactionCount;
    }

    //Payments
    function buyMessage() public payable{
        require(msg.value >= price);
    }

    function withdraw() external{
        require(msg.sender == iown);
        iown.transfer(address(this).balance);
    }

    function withdrawAmount(uint amount) external{
        require(msg.sender == iown);
        iown.transfer(amount);
    }

    //check accounts
    function checkAccount(address _a) external view returns (bool){
        if(users[_a].id == 0){
         return false;
       }
       else{
         return true;
       }
    }

    function amIin() external view returns (bool){
        if(users[msg.sender].id == 0){
            return false;
        }
        else{
            return true;
        }
    }

}