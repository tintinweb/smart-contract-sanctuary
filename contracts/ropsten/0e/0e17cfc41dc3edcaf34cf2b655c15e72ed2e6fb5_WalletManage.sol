/**
 *Submitted for verification at Etherscan.io on 2021-05-15
*/

pragma solidity ^ 0.4 .18;

interface ERC20Interface {
    function transfer(address _to, uint256 _value) external returns(bool success);
    function balanceOf(address _owner) external constant returns(uint256 balance);
}

interface ERC721Interface {
    function transferFrom(address _from, address _to, uint256 _tokenId) external returns(bool success);
    function balanceOf(address _owner) external constant returns(uint256);
}

contract WalletOwned {
    address public owner;
    address public manager;
    address public operation;

    constructor() public {
        owner = msg.sender;
    }

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    modifier onlyManager {
        require(msg.sender == manager);
        _;
    }

    modifier onlyOperation {
        require(msg.sender == operation || msg.sender == manager);
        _;
    }

    modifier onlyOwnerOrManager {
        require(msg.sender == owner || msg.sender == manager);
        _;
    }

    modifier onlyManagerOrOperation {
        require(msg.sender == operation || msg.sender == manager);
        _;
    }

    function transferOwnership(address newOwner) onlyOwner public {
        owner = newOwner;
    }

    function setManager(address newManager) onlyOwnerOrManager public {
        manager = newManager;
    }

    function setOperation(address newOperation) onlyOwnerOrManager public {
        operation = newOperation;
    }

}

contract WalletManage is WalletOwned {
    enum State{On,Off}
    
    mapping (address => bool) public listWallet;
    address private forwardAddress;
    State private allowStatus= State.Off;
    State public depositStatus= State.On;
    
    event CreateWallet(address _wallet);
    event ForwardAddress(address _wallet);
    event Deposited(address _from,address _wallet, uint _amount);

    modifier blockDeposit() {
        require(allowStatus == State.On,"Deposit is not allowed");
        _;
    }
    modifier walletOnly {
        require(listWallet[msg.sender]);
        _;
    }
    function() public payable blockDeposit { }
    function setHistory(address _from,address _wallet, uint _amount) walletOnly public {
        emit Deposited(_from,_wallet,_amount);
    }
    function setOn() onlyOwnerOrManager public {
        depositStatus = State.On;
    }

    function setOff() onlyOwnerOrManager public {
        depositStatus = State.Off;
    }
    
    function createWallet() public onlyOperation {
        address childAddress = new Wallet();
        listWallet[childAddress] = true;
        emit CreateWallet(childAddress);
    }

    function setForwardAddress(address _value) public onlyManager {
        forwardAddress = _value;
        emit ForwardAddress(forwardAddress);
    }

    function getForwardAddress() public view returns(address) {
        return forwardAddress;
    }
    
    function getDepositStatus() public view returns(State) {
        return depositStatus;
    }
    
    function flushERC(address tokenContractAddress) public {
        ERC20Interface instance = ERC20Interface(tokenContractAddress);
        uint walletBalance = instance.balanceOf(address(this));
        if (walletBalance == 0) {
            return;
        }
        if (!instance.transfer(forwardAddress, walletBalance)) {
            revert();
        }
    }

    function flushNFT(address tokenContractAddress, uint256 tokenId) public {
        ERC721Interface instance = ERC721Interface(tokenContractAddress);
        if (!instance.transferFrom(address(this), forwardAddress, tokenId)) {
            revert();
        }
    }
}


contract Wallet {
    WalletManage parentInstance;
    address public parentAddress;
    event Deposited(address _from,address _wallet, uint _amount);
    event ForwardDeposit(address _wallet,address _to, uint _amount);
    modifier blockDeposit() {
        require(parentInstance.getDepositStatus() == WalletManage.State.On,"Deposit is not allowed");
        _;
    }
    
    constructor() public {
        parentInstance = WalletManage(msg.sender);
        parentAddress = msg.sender;
    }

    function() public payable blockDeposit {
        address forwardAddress = parentInstance.getForwardAddress();
        forwardAddress.transfer(msg.value);
        parentInstance.setHistory(msg.sender,address(this),msg.value);
        emit Deposited(msg.sender,address(this),msg.value);
        emit ForwardDeposit(address(this),forwardAddress,msg.value);
    }

    function flushETH() public {
        address forwardAddress = parentInstance.getForwardAddress();
        forwardAddress.transfer(address(this).balance);
    }

    function flushERC(address tokenContractAddress) public {
        ERC20Interface instance = ERC20Interface(tokenContractAddress);
        uint walletBalance = instance.balanceOf(address(this));
        address forwardAddress = parentInstance.getForwardAddress();
        if (walletBalance == 0) {
            return;
        }
        if (!instance.transfer(forwardAddress, walletBalance)) {
            revert();
        }
    }

    function flushNFT(address tokenContractAddress, uint256 tokenId) public {
        ERC721Interface instance = ERC721Interface(tokenContractAddress);
        address forwardAddress = parentInstance.getForwardAddress();
        if (!instance.transferFrom(address(this), forwardAddress, tokenId)) {
            revert();
        }
    }

}