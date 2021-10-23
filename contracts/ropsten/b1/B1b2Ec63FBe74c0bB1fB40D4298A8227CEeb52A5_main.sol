pragma solidity 0.8.9;

//version alpha, not final one. Just for checking the feedback from users. if all goes good, next setup is to reduce the gas cost for deployment and user interaction
//Smart contract developed for user to store their Passwords in secure way, so that only they can access it provided with their account.
//0x584fAAF8bE20aa6D47b5Ff122723f4b9b2Ae4a6d
contract main {
    address public creater;
   
    //store the users name, plays crucial role in checking their stored passwords
    struct userDetails {
        string name;
    }

    mapping(address => userDetails) private usermap; 

    mapping(address => mapping(string => string)) private userstoreinfo;

    constructor() 
        public 
    {
        creater = msg.sender;
    }

    /**
     * @dev Sets password for the users subject (subject can be like gmail, slack, instagram, facebook etc).
     *
     *
     * Requirements:
     *
     * - User has to be registered.
     */
    function set(string memory subject, string memory pass)
        public 
    {
        bytes memory bytesname = bytes(usermap[msg.sender].name);
        require(bytesname.length != 0, "You didnt register");
        userstoreinfo[msg.sender][subject] = pass;
    }
 
    /**
     * @dev Registers a user with the name provided.
     *
     *
     * Requirements:
     *
     * - User cannot register more than once. Once done there is no way to change name with the used account
     */
    function Register(string memory _name)
        public
        userCheck(msg.sender)
        returns (bool)
    {
        usermap[msg.sender].name = _name;
        return true;
    }

    /**
     * @dev User can get the password for the subject they had set.
     *
     *
     * Requirements:
     *
     * - User has to be regestered, returns nothing if given a undefined subject.
     */
    function get(string memory name, string memory subject)
        public
        view
        returns (string memory)
    {
        require(
            keccak256(abi.encodePacked(usermap[msg.sender].name)) ==
                keccak256(abi.encodePacked(name)), "Invalid name"
        );
        return userstoreinfo[msg.sender][subject];
    }
 
    //this funciton works, but under improvement for gas consumption check
    function support()
        public payable
    {
        (bool sent, bytes memory data) = creater.call{value: msg.value}("");
        require(sent, "Failed to send Ether");
    }
    
    //modifier to check an user registers only once
    modifier userCheck(address a) {
        bytes memory bytesname = bytes(usermap[a].name);
        require(bytesname.length == 0, "already exisit");
        _;
    }
}