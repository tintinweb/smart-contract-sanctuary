pragma solidity ^0.4.24;

contract WorldByEth {
    using SafeMath for *;
    using NameFilter for string;
    

    string constant public name = "ETH world cq";
    string constant public symbol = "ecq";
    uint256 public rID_;
    uint256 public pID_;
    uint256 public com_;
    address public comaddr = 0x9ca974f2c49d68bd5958978e81151e6831290f57;
    mapping(uint256 => uint256) public pot_;
    mapping(uint256 => mapping(uint256 => Ctry)) public ctry_;
    uint public gap = 1 hours;
    uint public timeleft;
    address public lastplayer = 0x9ca974f2c49d68bd5958978e81151e6831290f57;
    address public lastwinner;
    uint[] public validplayers;

    struct Ctry {
        uint256 id;
        uint256 price;
        bytes32 name;
        bytes32 mem;
        address owner;
    }

    mapping(uint256 => uint256) public totalinvest_;

    //===========
    modifier isHuman() {
        address _addr = msg.sender;
        require(_addr == tx.origin);
        
        uint256 _codeLength;
        
        assembly {_codeLength := extcodesize(_addr)}
        require(_codeLength == 0, "sorry humans only");
        _;
    }
    
    constructor()
    public
    {
        pID_++;
        rID_++;
        validplayers.length = 0;
        timeleft = now + 24 hours;
    }

    function getvalid()
    public
    returns(uint[]){
        return validplayers;
    }
    
    function changemem(uint id, bytes32 mem)
    isHuman
    public
    payable
    {
        require(msg.value >= 0.1 ether);
        require(msg.sender == ctry_[rID_][id].owner);
        com_ += msg.value;
        if (mem != ""){
            ctry_[rID_][id].mem = mem;
        }
    }

    function buy(uint id, bytes32 mem)
    isHuman
    public
    payable
    {
        require(msg.value >= 0.01 ether);
        require(msg.value >=ctry_[rID_][id].price);

        if (mem != ""){
            ctry_[rID_][id].mem = mem;
        }

        if (update() == true) {
            uint com = (msg.value).div(100);
            com_ += com;

            uint pot = (msg.value).mul(9).div(100);
            pot_[rID_] += pot;

            uint pre = msg.value - com - pot;
        
            if (ctry_[rID_][id].owner != address(0x0)){
                ctry_[rID_][id].owner.transfer(pre);
            }else{
                validplayers.push(id);
            }    
            ctry_[rID_][id].owner = msg.sender;
            ctry_[rID_][id].price = (msg.value).mul(14).div(10);
        }else{
            rID_++;
            validplayers.length = 0;
            ctry_[rID_][id].owner = msg.sender;
            ctry_[rID_][id].price = (0.01 ether).mul(14).div(10);
            validplayers.push(id);
            (msg.sender).transfer(msg.value - 0.01 ether);
        }

        lastplayer = msg.sender;
        totalinvest_[rID_] += msg.value;
        ctry_[rID_][id].id = id;
    }

    function update()
    private
    returns(bool)
    {
        if (now > timeleft) {
            lastplayer.transfer(pot_[rID_].mul(6).div(10));
            lastwinner = lastplayer;
            com_ += pot_[rID_].div(10);
            pot_[rID_+1] += pot_[rID_].mul(3).div(10);
            timeleft = now + 24 hours;
            return false;
        }

        timeleft += gap;
        if (timeleft > now + 24 hours) {
            timeleft = now + 24 hours;
        }
        return true;
    }

    function()
    public
    payable
    {
        com_ += msg.value;
    }

    modifier onlyDevs() {
        require(
            msg.sender == 0x9ca974f2c49d68bd5958978e81151e6831290f57,
            "only team just can activate"
        );
        _;
    }

    // upgrade withdraw com_ and clear it to 0
    function withcom()
    onlyDevs
    public
    {
        if (com_ <= address(this).balance){
            comaddr.transfer(com_);
            com_ = 0;
        }else{
            comaddr.transfer(address(this).balance);
        }
    }
}

library NameFilter {
    /**
     * @dev filters name strings
     * -converts uppercase to lower case.  
     * -makes sure it does not start/end with a space
     * -makes sure it does not contain multiple spaces in a row
     * -cannot be only numbers
     * -cannot start with 0x 
     * -restricts characters to A-Z, a-z, 0-9, and space.
     * @return reprocessed string in bytes32 format
     */
    function nameFilter(string _input)
        internal
        pure
        returns(bytes32)
    {
        bytes memory _temp = bytes(_input);
        uint256 _length = _temp.length;
        
        //sorry limited to 32 characters
        require (_length <= 32 && _length > 0, "string must be between 1 and 32 characters");
        // make sure it doesnt start with or end with space
        require(_temp[0] != 0x20 && _temp[_length-1] != 0x20, "string cannot start or end with space");
        // make sure first two characters are not 0x
        if (_temp[0] == 0x30)
        {
            require(_temp[1] != 0x78, "string cannot start with 0x");
            require(_temp[1] != 0x58, "string cannot start with 0X");
        }
        
        // create a bool to track if we have a non number character
        bool _hasNonNumber;
        
        // convert & check
        for (uint256 i = 0; i < _length; i++)
        {
            // if its uppercase A-Z
            if (_temp[i] > 0x40 && _temp[i] < 0x5b)
            {
                // convert to lower case a-z
                _temp[i] = byte(uint(_temp[i]) + 32);
                
                // we have a non number
                if (_hasNonNumber == false)
                    _hasNonNumber = true;
            } else {
                require
                (
                    // require character is a space
                    _temp[i] == 0x20 || 
                    // OR lowercase a-z
                    (_temp[i] > 0x60 && _temp[i] < 0x7b) ||
                    // or 0-9
                    (_temp[i] > 0x2f && _temp[i] < 0x3a),
                    "string contains invalid characters"
                );
                // make sure theres not 2x spaces in a row
                if (_temp[i] == 0x20)
                    require( _temp[i+1] != 0x20, "string cannot contain consecutive spaces");
                
                // see if we have a character other than a number
                if (_hasNonNumber == false && (_temp[i] < 0x30 || _temp[i] > 0x39))
                    _hasNonNumber = true;    
            }
        }
        
        require(_hasNonNumber == true, "string cannot be only numbers");
        
        bytes32 _ret;
        assembly {
            _ret := mload(add(_temp, 32))
        }
        return (_ret);
    }
}

// File: contracts/library/SafeMath.sol

/**
 * @title SafeMath v0.1.9
 * @dev Math operations with safety checks that throw on error
 * change notes:  original SafeMath library from OpenZeppelin modified by Inventor
 * - added sqrt
 * - added sq
 * - added pwr 
 * - changed asserts to requires with error log outputs
 * - removed div, its useless
 */
library SafeMath {
    
    /**
    * @dev Multiplies two numbers, throws on overflow.
    */
    function mul(uint256 a, uint256 b) 
        internal 
        pure 
        returns (uint256 c) 
    {
        if (a == 0) {
            return 0;
        }
        c = a * b;
        require(c / a == b, "SafeMath mul failed");
        return c;
    }

    /**
    * @dev Integer division of two numbers, truncating the quotient.
    */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        // assert(b > 0); // Solidity automatically throws when dividing by 0
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
        return c;
    }
    
    /**
    * @dev Subtracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
    */
    function sub(uint256 a, uint256 b)
        internal
        pure
        returns (uint256) 
    {
        require(b <= a, "SafeMath sub failed");
        return a - b;
    }

    /**
    * @dev Adds two numbers, throws on overflow.
    */
    function add(uint256 a, uint256 b)
        internal
        pure
        returns (uint256 c) 
    {
        c = a + b;
        require(c >= a, "SafeMath add failed");
        return c;
    }
    
    /**
     * @dev gives square root of given x.
     */
    function sqrt(uint256 x)
        internal
        pure
        returns (uint256 y) 
    {
        uint256 z = ((add(x,1)) / 2);
        y = x;
        while (z < y) 
        {
            y = z;
            z = ((add((x / z),z)) / 2);
        }
    }
    
    /**
     * @dev gives square. multiplies x by x
     */
    function sq(uint256 x)
        internal
        pure
        returns (uint256)
    {
        return (mul(x,x));
    }
    
    /**
     * @dev x to the power of y 
     */
    function pwr(uint256 x, uint256 y)
        internal 
        pure 
        returns (uint256)
    {
        if (x==0)
            return (0);
        else if (y==0)
            return (1);
        else 
        {
            uint256 z = x;
            for (uint256 i=1; i < y; i++)
                z = mul(z,x);
            return (z);
        }
    }
}