pragma solidity ^0.4.21;

library StringUtils {
    // Tests for uppercase characters in a given string
    function allLower(string memory _string) internal pure returns (bool) {
        bytes memory bytesString = bytes(_string);
        for (uint i = 0; i < bytesString.length; i++) {
            if ((bytesString[i] >= 65) && (bytesString[i] <= 90)) {  // Uppercase characters
                return false;
            }
        }
        return true;
    }
}

contract Ownable {
    address public owner;


    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);


    /**
    * @dev The Ownable constructor sets the original `owner` of the contract to the sender
    * account.
    */
    function Ownable() public {
        owner = msg.sender;
    }

    /**
    * @dev Throws if called by any account other than the owner.
    */
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    /**
    * @dev Allows the current owner to transfer control of the contract to a newOwner.
    * @param newOwner The address to transfer ownership to.
    */
    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0));
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }

}

contract ERC20Basic {
    function totalSupply() public view returns (uint256);
    function balanceOf(address who) public view returns (uint256);
    function transfer(address to, uint256 value) public returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
}

contract Withdrawable is Ownable {
    // Allows owner to withdraw ether from the contract
    function withdrawEther(address to) public onlyOwner {
        to.transfer(address(this).balance);
    }

    // Allows owner to withdraw ERC20 tokens from the contract
    function withdrawERC20Token(address tokenAddress, address to) public onlyOwner {
        ERC20Basic token = ERC20Basic(tokenAddress);
        token.transfer(to, token.balanceOf(address(this)));
    }
}


interface HydroToken {
    function balanceOf(address _owner) external returns (uint256 balance);
}


contract RaindropClient is Withdrawable {
    // Events for when a user signs up for Raindrop Client and when their account is deleted
    event UserSignUp(string userName, address userAddress, bool official);
    event UserDeleted(string userName, address userAddress, bool official);
    // Events for when an application signs up for Raindrop Client and when their account is deleted
    event ApplicationSignUp(string applicationName, bool official);
    event ApplicationDeleted(string applicationName, bool official);

    using StringUtils for string;

    // Fees that unofficial users/applications must pay to sign up for Raindrop Client
    uint public unofficialUserSignUpFee;
    uint public unofficialApplicationSignUpFee;

    address public hydroTokenAddress;
    uint public hydroStakingMinimum;

    // User accounts
    struct User {
        string userName;
        address userAddress;
        bool official;
        bool _initialized;
    }

    // Application accounts
    struct Application {
        string applicationName;
        bool official;
        bool _initialized;
    }

    // Internally, users and applications are identified by the hash of their names
    mapping (bytes32 => User) internal userDirectory;
    mapping (bytes32 => Application) internal officialApplicationDirectory;
    mapping (bytes32 => Application) internal unofficialApplicationDirectory;

    // Allows the Hydro API to sign up official users with their app-generated address
    function officialUserSignUp(string userName, address userAddress) public onlyOwner {
        _userSignUp(userName, userAddress, true);
    }

    // Allows anyone to sign up as an unofficial user with their own address
    function unofficialUserSignUp(string userName) public payable {
        require(bytes(userName).length < 100);
        require(msg.value >= unofficialUserSignUpFee);

        return _userSignUp(userName, msg.sender, false);
    }

    // Allows the Hydro API to delete official users iff they&#39;ve signed keccak256("Delete") with their private key
    function deleteUserForUser(string userName, uint8 v, bytes32 r, bytes32 s) public onlyOwner {
        bytes32 userNameHash = keccak256(userName);
        require(userNameHashTaken(userNameHash));
        address userAddress = userDirectory[userNameHash].userAddress;
        require(isSigned(userAddress, keccak256("Delete"), v, r, s));

        delete userDirectory[userNameHash];

        emit UserDeleted(userName, userAddress, true);
    }

    // Allows unofficial users to delete their account
    function deleteUser(string userName) public {
        bytes32 userNameHash = keccak256(userName);
        require(userNameHashTaken(userNameHash));
        address userAddress = userDirectory[userNameHash].userAddress;
        require(userAddress == msg.sender);

        delete userDirectory[userNameHash];

        emit UserDeleted(userName, userAddress, true);
    }

    // Allows the Hydro API to sign up official applications
    function officialApplicationSignUp(string applicationName) public onlyOwner {
        bytes32 applicationNameHash = keccak256(applicationName);
        require(!applicationNameHashTaken(applicationNameHash, true));
        officialApplicationDirectory[applicationNameHash] = Application(applicationName, true, true);

        emit ApplicationSignUp(applicationName, true);
    }

    // Allows anyone to sign up as an unofficial application
    function unofficialApplicationSignUp(string applicationName) public payable {
        require(bytes(applicationName).length < 100);
        require(msg.value >= unofficialApplicationSignUpFee);
        require(applicationName.allLower());

        HydroToken hydro = HydroToken(hydroTokenAddress);
        uint256 hydroBalance = hydro.balanceOf(msg.sender);
        require(hydroBalance >= hydroStakingMinimum);

        bytes32 applicationNameHash = keccak256(applicationName);
        require(!applicationNameHashTaken(applicationNameHash, false));
        unofficialApplicationDirectory[applicationNameHash] = Application(applicationName, false, true);

        emit ApplicationSignUp(applicationName, false);
    }

    // Allows the Hydro API to delete applications unilaterally
    function deleteApplication(string applicationName, bool official) public onlyOwner {
        bytes32 applicationNameHash = keccak256(applicationName);
        require(applicationNameHashTaken(applicationNameHash, official));
        if (official) {
            delete officialApplicationDirectory[applicationNameHash];
        } else {
            delete unofficialApplicationDirectory[applicationNameHash];
        }

        emit ApplicationDeleted(applicationName, official);
    }

    // Allows the Hydro API to changes the unofficial user fee
    function setUnofficialUserSignUpFee(uint newFee) public onlyOwner {
        unofficialUserSignUpFee = newFee;
    }

    // Allows the Hydro API to changes the unofficial application fee
    function setUnofficialApplicationSignUpFee(uint newFee) public onlyOwner {
        unofficialApplicationSignUpFee = newFee;
    }

    // Allows the Hydro API to link to the Hydro token
    function setHydroContractAddress(address _hydroTokenAddress) public onlyOwner {
        hydroTokenAddress = _hydroTokenAddress;
    }

    // Allows the Hydro API to set a minimum hydro balance required to register unofficially
    function setHydroStakingMinimum(uint newMinimum) public onlyOwner {
        hydroStakingMinimum = newMinimum;
    }

    // Indicates whether a given user name has been claimed
    function userNameTaken(string userName) public view returns (bool taken) {
        bytes32 userNameHash = keccak256(userName);
        return userDirectory[userNameHash]._initialized;
    }

    // Indicates whether a given application name has been claimed for official and unofficial applications
    function applicationNameTaken(string applicationName)
        public
        view
        returns (bool officialTaken, bool unofficialTaken)
    {
        bytes32 applicationNameHash = keccak256(applicationName);
        return (
            officialApplicationDirectory[applicationNameHash]._initialized,
            unofficialApplicationDirectory[applicationNameHash]._initialized
        );
    }

    // Returns user details by user name
    function getUserByName(string userName) public view returns (address userAddress, bool official) {
        bytes32 userNameHash = keccak256(userName);
        require(userNameHashTaken(userNameHash));
        User storage _user = userDirectory[userNameHash];

        return (_user.userAddress, _user.official);
    }

    // Checks whether the provided (v, r, s) signature was created by the private key associated with _address
    function isSigned(address _address, bytes32 messageHash, uint8 v, bytes32 r, bytes32 s) public pure returns (bool) {
        return ecrecover(messageHash, v, r, s) == _address;
    }

    // Common internal logic for all user signups
    function _userSignUp(string userName, address userAddress, bool official) internal {
        bytes32 userNameHash = keccak256(userName);
        require(!userNameHashTaken(userNameHash));
        userDirectory[userNameHash] = User(userName, userAddress, official, true);

        emit UserSignUp(userName, userAddress, official);
    }

    // Internal check for whether a user name has been taken
    function userNameHashTaken(bytes32 userNameHash) internal view returns (bool) {
        return userDirectory[userNameHash]._initialized;
    }

    // Internal check for whether an application name has been taken
    function applicationNameHashTaken(bytes32 applicationNameHash, bool official) internal view returns (bool) {
        if (official) {
            return officialApplicationDirectory[applicationNameHash]._initialized;
        } else {
            return unofficialApplicationDirectory[applicationNameHash]._initialized;
        }
    }
}