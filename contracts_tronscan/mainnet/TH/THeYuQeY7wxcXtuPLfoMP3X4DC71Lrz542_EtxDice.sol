//SourceUnit: etxdice.sol

pragma solidity ^0.4.25;

contract MyOwner {
    address public owner;

    constructor() public {
        owner = msg.sender;
    }

    modifier OnlyOwner() {
        require(msg.sender == owner);
        _;
    }

    function getBalance() public view returns (uint256) {
        return address(this).balance;
    }

    function transferToOwner() public OnlyOwner {
        owner.transfer(address(this).balance);
    }
}

library StringsUtil {
    function strConcat(string _a, string _b)pure internal returns (string){
        bytes memory _ba = bytes(_a);
        bytes memory _bb = bytes(_b);
        string memory ret = new string(_ba.length + _bb.length);
        bytes memory bret = bytes(ret);
        uint k = 0;
        for (uint i = 0; i < _ba.length; i++)bret[k++] = _ba[i];
        for (i = 0; i < _bb.length; i++) bret[k++] = _bb[i];
        return string(ret);
   }  

    function getIndexString(string str, uint256 i)
        internal
        pure
        returns (byte)
    {
        bytes memory strBytes = bytes(str);

        byte indexB = strBytes[i];

        return indexB;
    }

    function getStringLength(string str) internal pure returns (uint256) {
        bytes memory strBytes = bytes(str);

        uint256 strLength = strBytes.length;

        return strLength;
    }

    function uint2str(uint256 i) internal pure returns (string c) {
        if (i == 0) return "0";
        uint256 j = i;
        uint256 length;
        while (j != 0) {
            length++;
            j /= 10;
        }
        bytes memory bstr = new bytes(length);
        uint256 k = length - 1;
        while (i != 0) {
            bstr[k--] = bytes1(48 + (i % 10));
            i /= 10;
        }
        c = string(bstr);
    }
}

library SafeMath {
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b);

        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0); // Solidity only automatically asserts when dividing by 0
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
     * @dev Subtracts two numbers, reverts on overflow (i.e. if subtrahend is greater than minuend).
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        if (b > a) {
            return 0;
        } else {
            uint256 c = a - b;
            return c;
        }
    }

    /**
     * @dev Adds two numbers, reverts on overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a);

        return c;
    }

    /**
     * @dev Divides two numbers and returns the remainder (unsigned integer modulo),
     * reverts when dividing by zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0);
        return a % b;
    }
}

contract EtxDice is MyOwner {
    uint256 minBet = 10000000;
    uint256 maxBet = 2000000000;


    event boardHash(uint8 rand);

    event betResult(address user, string bet, uint8 result, uint256 reward);

    function checkBetInfo(string betInfo) private pure returns (bool) {
        bytes memory strBytes = bytes(betInfo);

        uint256 strLength = strBytes.length;

        require(strLength <= 5, "bet length error");

        for (uint256 i = 0; i < strLength; i++) {
            require(checkStr(strBytes[i]), "bet info error");
        }
        return true;
    }

    function checkStr(bytes1 i) private pure returns (bool) {
        if (i == '6') {
            return true;
        }
        if (i == '5') {
            return true;
        }
        if (i == '4') {
            return true;
        }
        if (i == '3') {
            return true;
        }
        if (i == '2') {
            return true;
        }
        if (i == '1') {
            return true;
        }
        return false;
    }

    function doBet(string betInfo) public payable returns (string) {
        require(checkBetInfo(betInfo));

        require(msg.value >= minBet && msg.value <= maxBet, "bet count error");

        uint8 game_random = random(6)+1;

        string memory game_rand_str = StringsUtil.uint2str(game_random);

        byte game_rand_byte = StringsUtil.getIndexString(game_rand_str, 0);

        uint256 strLength = StringsUtil.getStringLength(betInfo);
        //抽水3%

        uint256 reward =SafeMath.div(SafeMath.mul(msg.value, SafeMath.div((6-strLength)*97*1000000, strLength*100)),1000000)+msg.value;

        bool isReward = false;
        for (uint256 i = 0; i < strLength; i++) {
            bytes1 indexChar = StringsUtil.getIndexString(betInfo, i);
            if (indexChar == game_rand_byte) {
                isReward = true;
            }
        }
        uint256 resultReward = 0;
        if (isReward) {
            uint256 balance = getBalance();

            if (balance >= reward) {
                resultReward = reward;
                emit betResult(msg.sender, betInfo, game_random, reward);
                msg.sender.transfer(reward);
            } else {
                resultReward = msg.value;
                msg.sender.transfer(msg.value);
                emit betResult(msg.sender, betInfo, 0, resultReward);
            }
        } else {
            resultReward = 0;
            emit betResult(msg.sender, betInfo, game_random, 0);
        }

        return StringsUtil.strConcat(game_rand_str,StringsUtil.strConcat("|",StringsUtil.uint2str(resultReward)));
    }
    
    function random(uint8 maxInt) private view returns (uint8) {
        return
            uint8(
                uint256(keccak256(block.timestamp, block.difficulty)) % maxInt
            );
    }
}