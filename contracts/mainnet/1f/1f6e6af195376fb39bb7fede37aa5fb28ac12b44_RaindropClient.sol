pragma solidity ^0.4.21;

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

contract RaindropClient is Withdrawable {
    // Events for when a user signs up for Raindrop Client and when their account is deleted
    event UserSignUp(string userName, address userAddress, bool delegated);
    event UserDeleted(string userName);

    // Variables allowing this contract to interact with the Hydro token
    address public hydroTokenAddress;
    uint public minimumHydroStakeUser;
    uint public minimumHydroStakeDelegatedUser;

    // User account template
    struct User {
        string userName;
        address userAddress;
        bool delegated;
        bool _initialized;
    }

    // Mapping from hashed names to users (primary User directory)
    mapping (bytes32 => User) internal userDirectory;
    // Mapping from addresses to hashed names (secondary directory for account recovery based on address)
    mapping (address => bytes32) internal nameDirectory;

    // Requires an address to have a minimum number of Hydro
    modifier requireStake(address _address, uint stake) {
        ERC20Basic hydro = ERC20Basic(hydroTokenAddress);
        require(hydro.balanceOf(_address) >= stake);
        _;
    }

    // Allows applications to sign up users on their behalf iff users signed their permission
    function signUpDelegatedUser(string userName, address userAddress, uint8 v, bytes32 r, bytes32 s)
        public
        requireStake(msg.sender, minimumHydroStakeDelegatedUser)
    {
        require(isSigned(userAddress, keccak256("Create RaindropClient Hydro Account"), v, r, s));
        _userSignUp(userName, userAddress, true);
    }

    // Allows users to sign up with their own address
    function signUpUser(string userName) public requireStake(msg.sender, minimumHydroStakeUser) {
        return _userSignUp(userName, msg.sender, false);
    }

    // Allows users to delete their accounts
    function deleteUser() public {
        bytes32 userNameHash = nameDirectory[msg.sender];
        require(userDirectory[userNameHash]._initialized);

        string memory userName = userDirectory[userNameHash].userName;

        delete nameDirectory[msg.sender];
        delete userDirectory[userNameHash];

        emit UserDeleted(userName);
    }

    // Allows the Hydro API to link to the Hydro token
    function setHydroTokenAddress(address _hydroTokenAddress) public onlyOwner {
        hydroTokenAddress = _hydroTokenAddress;
    }

    // Allows the Hydro API to set minimum hydro balances required for sign ups
    function setMinimumHydroStakes(uint newMinimumHydroStakeUser, uint newMinimumHydroStakeDelegatedUser) public {
        ERC20Basic hydro = ERC20Basic(hydroTokenAddress);
        require(newMinimumHydroStakeUser <= (hydro.totalSupply() / 100 / 10)); // <= .1% of total supply
        require(newMinimumHydroStakeDelegatedUser <= (hydro.totalSupply() / 100)); // <= 1% of total supply
        minimumHydroStakeUser = newMinimumHydroStakeUser;
        minimumHydroStakeDelegatedUser = newMinimumHydroStakeDelegatedUser;
    }

    // Returns a bool indicated whether a given userName has been claimed
    function userNameTaken(string userName) public view returns (bool taken) {
        bytes32 userNameHash = keccak256(userName);
        return userDirectory[userNameHash]._initialized;
    }

    // Returns user details by user name
    function getUserByName(string userName) public view returns (address userAddress, bool delegated) {
        bytes32 userNameHash = keccak256(userName);
        User storage _user = userDirectory[userNameHash];
        require(_user._initialized);

        return (_user.userAddress, _user.delegated);
    }

    // Returns user details by user address
    function getUserByAddress(address _address) public view returns (string userName, bool delegated) {
        bytes32 userNameHash = nameDirectory[_address];
        User storage _user = userDirectory[userNameHash];
        require(_user._initialized);

        return (_user.userName, _user.delegated);
    }

    // Checks whether the provided (v, r, s) signature was created by the private key associated with _address
    function isSigned(address _address, bytes32 messageHash, uint8 v, bytes32 r, bytes32 s) public pure returns (bool) {
        return (_isSigned(_address, messageHash, v, r, s) || _isSignedPrefixed(_address, messageHash, v, r, s));
    }

    // Checks unprefixed signatures
    function _isSigned(address _address, bytes32 messageHash, uint8 v, bytes32 r, bytes32 s)
        internal
        pure
        returns (bool)
    {
        return ecrecover(messageHash, v, r, s) == _address;
    }

    // Checks prefixed signatures (e.g. those created with web3.eth.sign)
    function _isSignedPrefixed(address _address, bytes32 messageHash, uint8 v, bytes32 r, bytes32 s)
        internal
        pure
        returns (bool)
    {
        bytes memory prefix = "\x19Ethereum Signed Message:\n32";
        bytes32 prefixedMessageHash = keccak256(prefix, messageHash);

        return ecrecover(prefixedMessageHash, v, r, s) == _address;
    }

    // Common internal logic for all user signups
    function _userSignUp(string userName, address userAddress, bool delegated) internal {
        require(bytes(userName).length < 100);
        bytes32 userNameHash = keccak256(userName);
        require(!userDirectory[userNameHash]._initialized);

        userDirectory[userNameHash] = User(userName, userAddress, delegated, true);
        nameDirectory[userAddress] = userNameHash;

        emit UserSignUp(userName, userAddress, delegated);
    }
}