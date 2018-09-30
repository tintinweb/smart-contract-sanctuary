pragma solidity ^0.4.24;

contract ToknTalkToken {

    event Transfer(address indexed from, address indexed to, uint amount);
    event Approval(address indexed owner, address indexed spender, uint amount);

    uint private constant MAX_UINT = 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF;

    address public mintSigner = msg.sender;
    string public constant name = "tokntalk.club";
    string public constant symbol = "TTT";
    uint public constant decimals = 0;
    uint public totalSupply = 0;
    mapping (address => uint) public balanceOf;
    mapping (address => mapping (address => uint)) public allowance;
    mapping (address => uint) public mintedBy;

    function transfer(address to, uint amount) external returns (bool) {
        require(to != address(this));
        require(to != 0);
        uint balanceOfMsgSender = balanceOf[msg.sender];
        require(balanceOfMsgSender >= amount);
        balanceOf[msg.sender] = balanceOfMsgSender - amount;
        balanceOf[to] += amount;
        emit Transfer(msg.sender, to, amount);
        return true;
    }

    function transferFrom(address from, address to, uint amount) external returns (bool) {
        require(to != address(this));
        require(to != 0);
        uint allowanceMsgSender = allowance[from][msg.sender];
        require(allowanceMsgSender >= amount);
        if (allowanceMsgSender != MAX_UINT) {
            allowance[from][msg.sender] = allowanceMsgSender - amount;
        }
        uint balanceOfFrom = balanceOf[from];
        require(balanceOfFrom >= amount);
        balanceOf[from] = balanceOfFrom - amount;
        balanceOf[to] += amount;
        emit Transfer(from, to, amount);
        return true;
    }

    function approve(address spender, uint amount) external returns (bool) {
        allowance[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }

    function mintUsingSignature(uint max, uint8 v, bytes32 r, bytes32 s) external {
        bytes memory maxString = toString(max);
        bytes memory messageLengthString = toString(124 + maxString.length);
        bytes32 hash = keccak256(abi.encodePacked(
            "\x19Ethereum Signed Message:\n",
            messageLengthString,
            "I approve address 0x",
            toHexString(msg.sender),
            " to mint token 0x",
            toHexString(this),
            " up to ",
            maxString
        ));
        require(ecrecover(hash, v, r, s) == mintSigner);
        uint mintedByMsgSender = mintedBy[msg.sender];
        require(max > mintedByMsgSender);
        mintedBy[msg.sender] = max;
        balanceOf[msg.sender] += max - mintedByMsgSender;
        emit Transfer(0, msg.sender, max - mintedByMsgSender);
    }

    function toString(uint value) private pure returns (bytes) {
        uint tmp = value;
        uint lengthOfValue;
        do {
            lengthOfValue++;
            tmp /= 10;
        } while (tmp != 0);
        bytes memory valueString = new bytes(lengthOfValue);
        while (lengthOfValue != 0) {
            valueString[--lengthOfValue] = bytes1(48 + value % 10);
            value /= 10;
        }
        return valueString;
    }

    function toHexString(address addr) private pure returns (bytes) {
        uint addrUint = uint(addr);
        uint lengthOfAddr = 40;
        bytes memory addrString = new bytes(lengthOfAddr);
        while (addrUint != 0) {
            addrString[--lengthOfAddr] = bytes1((addrUint % 16 < 10 ? 0x30 : 0x57) + addrUint % 16);
            addrUint /= 16;
        }
        return addrString;
    }

    function setMintSigner(address newMintSigner) external {
        require(msg.sender == mintSigner);
        mintSigner = newMintSigner;
    }
}