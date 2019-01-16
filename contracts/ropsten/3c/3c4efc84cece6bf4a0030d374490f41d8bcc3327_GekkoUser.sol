pragma solidity 0.4.25;

library Helper {
    
    function bytes32ToString (bytes32 data)
        internal
        pure
        returns (string) 
    {
        bytes memory bytesString = new bytes(32);
        for (uint j=0; j<32; j++) {
            byte char = byte(bytes32(uint(data) * 2 ** (8 * j)));
            if (char != 0) {
                bytesString[j] = char;
            }
        }
        return string(bytesString);
    }
    
    function uintToBytes32(uint256 n)
        internal
        pure
        returns (bytes32) 
    {
        return bytes32(n);
    }
    
    function bytes32ToUint(bytes32 n) 
        internal
        pure
        returns (uint256) 
    {
        return uint256(n);
    }
    
    function stringToBytes32(string memory source) 
        internal
        pure
        returns (bytes32 result) 
    {
        bytes memory tempEmptyStringTest = bytes(source);
        if (tempEmptyStringTest.length == 0) {
            return 0x0;
        }

        assembly {
            result := mload(add(source, 32))
        }
    }
    
    function isVaidUsername(string _username)
        internal
        pure
        returns(bool)
    {
        uint256 len = bytes(_username).length;
        // username max length 6 - 32
        if ((len < 6) || (len > 32)) return false;
        // last character not space
        if (bytes(_username)[len-1] == 32) return false;
        // first character not zero
        return uint256(bytes(_username)[0]) != 48;
    }
    
    function stringToNumber(string memory source) 
        internal
        pure
        returns (uint256)
    {
        return bytes32ToUint(stringToBytes32(source));
    }
    
    function numberToString(uint256 _uint) 
        internal
        pure
        returns (string)
    {
        return bytes32ToString(uintToBytes32(_uint));
    }
}

library SafeMath {
    int256 constant private INT256_MIN = -2**255;

    /**
    * @dev Multiplies two unsigned integers, reverts on overflow.
    */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring &#39;a&#39; not being zero, but the
        // benefit is lost if &#39;b&#39; is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b);

        return c;
    }

    /**
    * @dev Multiplies two signed integers, reverts on overflow.
    */
    function mul(int256 a, int256 b) internal pure returns (int256) {
        // Gas optimization: this is cheaper than requiring &#39;a&#39; not being zero, but the
        // benefit is lost if &#39;b&#39; is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
        if (a == 0) {
            return 0;
        }

        require(!(a == -1 && b == INT256_MIN)); // This is the only case of overflow not detected by the check below

        int256 c = a * b;
        require(c / a == b);

        return c;
    }

    /**
    * @dev Integer division of two unsigned integers truncating the quotient, reverts on division by zero.
    */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold

        return c;
    }

    /**
    * @dev Integer division of two signed integers truncating the quotient, reverts on division by zero.
    */
    function div(int256 a, int256 b) internal pure returns (int256) {
        require(b != 0); // Solidity only automatically asserts when dividing by 0
        require(!(b == -1 && a == INT256_MIN)); // This is the only case of overflow

        int256 c = a / b;

        return c;
    }

    /**
    * @dev Subtracts two unsigned integers, reverts on overflow (i.e. if subtrahend is greater than minuend).
    */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a);
        uint256 c = a - b;

        return c;
    }

    /**
    * @dev Subtracts two signed integers, reverts on overflow.
    */
    function sub(int256 a, int256 b) internal pure returns (int256) {
        int256 c = a - b;
        require((b >= 0 && c <= a) || (b < 0 && c > a));

        return c;
    }

    /**
    * @dev Adds two unsigned integers, reverts on overflow.
    */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a);

        return c;
    }

    /**
    * @dev Adds two signed integers, reverts on overflow.
    */
    function add(int256 a, int256 b) internal pure returns (int256) {
        int256 c = a + b;
        require((b >= 0 && c >= a) || (b < 0 && c < a));

        return c;
    }

    /**
    * @dev Divides two unsigned integers and returns the remainder (unsigned integer modulo),
    * reverts when dividing by zero.
    */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0);
        return a % b;
    }
}


contract GekkoUser {
    using SafeMath for *;
    
    // check is not registered
    modifier notRegistered(){
        require(!isUser[msg.sender], "not registered");
        _;
    }
    
    // user data
    struct User{
        uint256 id;
        uint256 username;
        address ref;
        uint256 countMyRef;
        address[] myRef;
    }
    
    mapping (address => User) public user;
    mapping (address => bool) public isUser;
    mapping (uint256 => address) public usernameAddress;
    mapping (uint256 => address) public userIdAddress;
    
    uint256 public totalUser;
    address private owner;
    
    constructor (address _owner)
    public
    {
        owner = _owner;
        totalUser = 1;
        
        user[owner].id = totalUser;
        uint256 usernameUint = Helper.stringToNumber(&#39;gekko&#39;);
        user[owner].username = usernameUint;
        isUser[owner] = true;
        usernameAddress[usernameUint] = owner;
        userIdAddress[totalUser] = owner;
    }
    
    // ----------------------------------- //
    // --------- SET FUNCTION ------------ //
    // ----------------------------------- //
    
    // SIGN UP FUNCTION
    function signUp (string _username,address _ref) 
        public
        notRegistered() // check this address is not registered
    {
        address sender = msg.sender;
        require(Helper.isVaidUsername(_username), &#39;can not use this username&#39;);
        uint256 username = Helper.stringToNumber(_username);
        require(usernameAddress[username] == 0x0, "username already exist");
        totalUser++;
        usernameAddress[username] = sender;
        userIdAddress[totalUser] = sender;
        
        // direct ref
        address ref = isUser[_ref] ? _ref : owner;
        
        // add to database
        isUser[sender] = true;
        user[sender].id = totalUser;
        user[sender].username = username;
        user[sender].ref = ref;
        user[sender].countMyRef = 0;
        
        // add new ref for parent user
        user[ref].myRef[user[ref].countMyRef] = sender;
        user[ref].countMyRef++;
    }
    
    // ----------------------------------- //
    // --------- GET FUNCTION ------------ //
    // ----------------------------------- //
    
    function getUserInfo (address _address)
        public
        view
        returns (uint256,string,address,uint256,address[])
    {
        return (
            user[_address].id,
            Helper.numberToString(user[_address].username),
            user[_address].ref,
            user[_address].countMyRef,
            user[_address].myRef
        );
    }
    
    function getAddressByUsername (string _username)
        public
        view
        returns (address)
    {
        return usernameAddress[Helper.stringToNumber(_username)];
    }
    
    function getAddressByUserId (uint256 _id)
        public
        view
        returns (address)
    {
        return userIdAddress[_id];   
    }
    
}