pragma solidity 0.4.21;

interface MyTestToken {
    function transfer(address receiver, uint amount) external;
    function transferFrom(address from, address to, uint tokens) external returns (bool success);
    function totalSupply() external constant returns (uint);
}

// ----------------------------------------------------------------------------
// Safe maths
// ----------------------------------------------------------------------------
contract SafeMath {
    function safeAdd(uint a, uint b) public pure returns (uint c) {
        c = a + b;
        require(c >= a);
    }

    function safeSub(uint a, uint b) public pure returns (uint c) {
        require(b <= a);
        c = a - b;
    }

    function safeMul(uint a, uint b) public pure returns (uint c) {
        c = a * b;
        require(a == 0 || c / a == b);
    }

    function safeDiv(uint a, uint b) public pure returns (uint c) {
        require(b > 0);
        c = a / b;
    }
}

// ----------------------------------------------------------------------------
// Owned contract
// ----------------------------------------------------------------------------
contract Owned {
    address public owner;
    address public newOwner;

    event OwnershipTransferred(address indexed _from, address indexed _to);

    function Owned() public {
        owner = msg.sender;
    }

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    function transferOwnership(address _newOwner) public onlyOwner {
        newOwner = _newOwner;
    }

    function acceptOwnership() public {
        require(msg.sender == newOwner);
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
        newOwner = address(0);
    }
}

contract Crowdsale is Owned, SafeMath {
    address owner;
    address public tokenAddress;
    address public escrowAddress;
    uint256 public totalEthInWei;         // WEI is the smallest unit of ETH (the equivalent of cent in USD or satoshi in BTC). We&#39;ll store the total ETH raised via our ICO here.
    
    //MyTestToken public token = new MyTestToken();

    uint start = 1500379200;
    uint period = 28;
    uint amountPerEther = 750;

    function Crowdsale() public {
        owner = msg.sender;
        tokenAddress = 0x0;
        escrowAddress = owner;
    }

    function setTokenAddress(address newAddress)
    public onlyOwner returns (bool success) {
        tokenAddress = newAddress;

        return true;
    }

    function setEscrowAddress(address newAddress)
    public onlyOwner returns (bool success) {
        escrowAddress = newAddress;

        return true;
    }


    function getBalance() public constant returns (uint) {
        require(tokenAddress != 0x0);

        MyTestToken token = MyTestToken(tokenAddress);
        //token.transfer(msg.sender, safeMul(msg.value, 10000));
        return token.totalSupply();
    }

    modifier isUnderHardCap() {
        _;
    }

    modifier saleIsOn() {
        //require(now > start && now < start + period * 1 days);
        _;
    }

//    function contribute() public isUnderHardCap saleIsOn payable {
//        //require(escrowAddress != 0x0);
//        //require(tokenAddress != 0x0);
//        //multisig.transfer(msg.value);
//        //uint tokens = rate.mul(msg.value).div(1 ether);
//        //token.mint(msg.sender, tokens);
//        //owner.transfer(msg.value / 2); // trasfer back half
//        //owner.trasfer(msg.value);
//
//        //owner.transfer(msg.value);
//
//        MyTestToken token = MyTestToken(tokenAddress);
//        token.transfer(msg.sender, safeMul(msg.value, amountPerEther));
//        //emit Transfer(msg.sender, _to, _value);
//        if (msg.value > 0) {
//            require(escrowAddress != 0x0);
//            if (!escrowAddress.send(msg.value)) revert();
//        }
//    }
    
    function() external payable {
        totalEthInWei = totalEthInWei + msg.value;
        // todo check reserved amount require(balances[fundsWallet] >= amount);
        
        //require(escrowAddress != 0x0);
        //require(tokenAddress != 0x0);
        //multisig.transfer(msg.value);
        //uint tokens = rate.mul(msg.value).div(1 ether);
        //token.mint(msg.sender, tokens);
        //owner.transfer(msg.value / 2); // trasfer back half
        //owner.trasfer(msg.value);

        //owner.transfer(msg.value);

        if (owner != msg.sender) {
            MyTestToken token = MyTestToken(tokenAddress);
            token.transferFrom(owner, msg.sender, safeMul(msg.value, amountPerEther));
//            if (msg.value > 0) {
//                require(escrowAddress != 0x0);
//                if (!escrowAddress.send(msg.value)) revert();
//            }
            
            //Transfer ether to fundsWallet
            escrowAddress.transfer(msg.value);
        }
        //emit Transfer(msg.sender, _to, _value);
    }
}