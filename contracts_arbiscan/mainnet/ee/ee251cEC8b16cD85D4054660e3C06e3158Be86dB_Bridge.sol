/**
 *Submitted for verification at arbiscan.io on 2022-01-13
*/

// SPDX-License-Identifier: GPLv3
pragma solidity ^0.8.7;

interface ERC20 {
    function balanceOf(address who) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);
}

contract Ownable {
    address owner;
    constructor() {
        owner = msg.sender;
    }
    modifier onlyOwner() {
        require(msg.sender == owner, "only owner");
        _;
    }
    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0), "address is null");
        owner = newOwner;
    }
}

contract Bridge is Ownable {
   
    struct Need{
        uint amount;
        uint toChain;
        address sender;
        address toAddress;
        address tokenAddress;
        uint assetIndex;
    }
    mapping(uint => Need) public needs;

    uint    public totalNeeds = 0;
    string  public mainToken = 'TetherUSDT';
    address public ContectedEthereumBridge;
    uint    public EthereumShareOfOwner;
    address public ContectedArbitrumBridge;
    uint    public ArbitrumShareOfOwner;
    address public OwnerChainBridge;
    string  public TetherUSDTPool;
    uint    public totalLockedAmount;

    //=============================================
    //============= public function ===============
    //=============================================
    function deposit(uint _amount,uint _toChain,address _toAddress) external payable {
        address _tokenAddress = 0x0000000000000000000000000000000000000000;
        deposit_private(_amount,_tokenAddress, _toChain, _toAddress, 0);
    }

    function deposit(uint _amount,address _tokenAddress,uint _toChain,address _toAddress,uint _index) external payable {
        deposit_private(_amount,_tokenAddress,_toChain, _toAddress, _index);
    }

    function deposit_private(uint amount,address tokenAddress,uint toChain,address toAddress,uint index) private {
       
        needs[totalNeeds].amount = amount;
        needs[totalNeeds].toChain = toChain;
        needs[totalNeeds].sender = msg.sender;
        needs[totalNeeds].toAddress = toAddress;
        needs[totalNeeds].assetIndex = index;
        needs[totalNeeds].tokenAddress = tokenAddress;
        if(index!=0){
            ERC20(tokenAddress).transferFrom(msg.sender, address(this), amount);
        }
        totalNeeds = totalNeeds++;
    }

    function withdraw_private(uint amount,address tokenAddress,uint toChain,address toAddress,uint index) private {
       
        needs[totalNeeds].amount = amount;
        needs[totalNeeds].toChain = toChain;
        needs[totalNeeds].sender = msg.sender;
        needs[totalNeeds].toAddress = toAddress;
        needs[totalNeeds].assetIndex = index;
        needs[totalNeeds].tokenAddress = tokenAddress;
        totalNeeds = totalNeeds++;
    }

    function query_needs(uint index) external view returns(uint, uint, address, address, uint, address) {
        return (needs[index].amount, 
        needs[index].toChain, 
        needs[index].sender,  
        needs[index].toAddress, 
        needs[index].assetIndex, 
        needs[index].tokenAddress
        );
    }

    function fristSettings(address _first,uint _firstShare,address _second,uint _secondShare,address _third,string memory _fouth,uint _seveth) external onlyOwner {
        ContectedEthereumBridge  = _first;
        EthereumShareOfOwner     = _firstShare;
        ContectedArbitrumBridge  = _second;
        ArbitrumShareOfOwner     = _secondShare;
        OwnerChainBridge         = _third;
        TetherUSDTPool           = _fouth;
        totalLockedAmount        = _seveth;
    }

    function EthereumInfo() external view returns(address, uint, address, string memory,uint) {
        return (
        ContectedEthereumBridge, 
        EthereumShareOfOwner,
        OwnerChainBridge,  
        TetherUSDTPool, 
        totalLockedAmount
        );
    }

    function ArbitrumInfo() external view returns(address, uint, address, string memory,uint) {
        return (
        ContectedArbitrumBridge,
        ArbitrumShareOfOwner,
        OwnerChainBridge,  
        TetherUSDTPool, 
        totalLockedAmount
        );
    }

    function query_totalNeeds() external view returns(uint) {
        return (
            totalNeeds
        );
    }






}