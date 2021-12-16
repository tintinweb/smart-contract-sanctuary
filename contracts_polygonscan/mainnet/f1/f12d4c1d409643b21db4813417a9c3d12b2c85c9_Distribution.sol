/**
 *Submitted for verification at polygonscan.com on 2021-12-15
*/

// SPDX-License-Identifier: MIT
/*
Contract requires the following tuning:
for security reasons against reentry attacks all Coins and Contracts should be approved, holders and shares set and only then unfrozen:
1) approveCoin (0 for Native + all necessary ERC20)
2) Approve Donor Contract with Matic (toggleContract)
3) setHolder (as many times as many holders) (shares are in billionth units -- 1/totalShare)
4) unfreeze
5) Donor Contract should set operatorContract to This
*
withdraw native token via "govWithDraw"
withdraw ERC20 via "distribute"

0xF12d4C1D409643B21DB4813417A9C3d12b2C85c9 on Polygon Matic
*/

pragma solidity ^0.8.0;
// import "https://github.com/Auctoritas/openzeppelin-contracts/blob/main/contracts/token/ERC20/IERC20.sol";
// import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC20/IERC20.sol";
interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

interface Donor {
    function withDrawFromGov(uint _amount) external payable;
}

contract Distribution {
    event HolderSet(address indexed, uint indexed);
    event FrozenSince(uint indexed _moment); // triggers on setHolder ! Unfreeze checks Sum of Shares !
    event CoinApproved(address indexed, uint256 indexed);
    event ContractApproved(address indexed, uint256 indexed);
    event Received(address indexed, uint indexed _rec, uint indexed _total);
    event Requested(address indexed _contract, uint indexed _amount);
    event Distributed(address indexed _coin, uint indexed _amount);
    event WithDrawn(address indexed a, uint indexed _amount);
    event FinalSet(uint indexed _newTime);
    event OperatorSet(address indexed, uint indexed _mask);
    
    struct HolderInfo {
        address h; // Holder Address
        uint s; // Holder Share
    }
    
    uint constant totalShare = 1e9;
    address public auctor;
    address[3] public operators; // Holders; Unfreeze/Distr; Coin // 0x3B3006fCaB69F1ea022DB6D0e20DDD294FAaD179;
    
    mapping (address => uint) public approvedCoins;
    uint public coinApprovaIX;
    mapping (uint => address ) public coinsApproved;

    mapping (address => uint) public approvedContracts;
    uint public contractApprovaIX;
    mapping (uint => address ) public contractsApproved;

    address[] public holders;
    uint[] public freeHI; // Free Holder Indices
    mapping (address => uint) public shares; // in billionth

    uint public frozenSince;
    uint public finalVersion;
    
    function getHoldersInfo() external view returns( HolderInfo[] memory ) {
        HolderInfo[] memory hI = new HolderInfo[](holders.length);
        for(uint k = 0; k < holders.length; k++) {
            hI[k].h = holders[k];
            hI[k].s = shares[ holders[k] ];
        }
        return hI;
    }
    
    function unfreeze() external{
        require(msg.sender == operators[1]);
        uint s;
        for(uint k = 0; k < holders.length; k++)
            if( holders[k] != address(0) ) {
                require( shares[holders[k]] <= totalShare, "share overflow" );
                s += shares[holders[k]];
            }
        require( s == totalShare, "totalshare wrong" );
        frozenSince = 0; // Unfrozen
        emit FrozenSince(0);
    }
    
    receive() external payable {
        if( frozenSince == 0 && approvedCoins[address(0)] > 0 )
            distribute( address(0), address(this).balance );
        emit Received( msg.sender, msg.value, address(this).balance );
    }
    
    function govWithDraw(address con, uint amount) external {
        require(msg.sender == operators[1] || shares[msg.sender] > 0); // Op.1 OR Any Holder
        Donor(con).withDrawFromGov(amount);
        emit Requested(con, amount);
    }
    
    function distribute(address coin, uint amount) public payable {
        require( msg.sender == operators[1] || shares[msg.sender] > 0 || approvedContracts[msg.sender] > 0 );
        require( approvedCoins[coin] > 0 );
        require( frozenSince == 0 );

        if( coin != address(0) ) // ERC20
            require( IERC20(coin).balanceOf( address(this) ) >= amount );
        else // 0 address means MATIC !
            require(address(this).balance >= amount);
            
        // Proceed with Payments !
        uint payment;
        for( uint k = 0; k < holders.length; k++)
            if( holders[k] != address(0) ) {
                payment = amount * shares[ holders[k] ] / totalShare;
                if( coin != address(0) )
                    IERC20(coin).transfer( holders[k], payment);
                else
                    payable(holders[k]).transfer(payment);
            }
        emit Distributed( coin, amount );
    }
    
    function withDrawMatic(address payable a, uint amount) external payable {
        require( msg.sender == auctor && a != address(0) && finalVersion > block.timestamp );
        a.transfer(amount);
        emit WithDrawn(a, amount);
    }

    function delayFinalVersion(uint t) external {
        require(msg.sender == auctor && finalVersion > block.timestamp);
        finalVersion = block.timestamp + t;
        emit FinalSet(finalVersion);
    }

    constructor() {
        auctor = msg.sender;
        operators[0] = msg.sender; // HolderSet
        operators[1] = msg.sender; // Unfreeze / Distr
        operators[2] = msg.sender; // CoinSet
        // 0x3B3006fCaB69F1ea022DB6D0e20DDD294FAaD179;
        finalVersion = block.timestamp + 90 * 24 * 3600; // 90 days for testing by default
        emit FinalSet(finalVersion);
        frozenSince = block.timestamp;
    }
    
    function setOperators(address a, uint mask) external {
        uint bits = 1;
        for(uint k = 0; k < 3; k++) {
            if( bits & mask > 0 ) {
                require( msg.sender == auctor || msg.sender == operators[k] );
                operators[k] = a;
            }
            bits *= 2;
        }
        emit OperatorSet(a, mask);
    }
    
    function setHolder(address h, uint s) external {
        require(msg.sender == operators[0]);
        
        if(s > 0) { // add/mod Holder ('s share)
            if(shares[h] == 0) { // New Holder => ADD
                addHolder(h);
            }
            shares[ h ] = s;
        }
        else { // s == 0 delete ((holder or just)) share
            if(shares[h] > 0) {
                delHolder(h);
                delete shares[h];
            }
        }
        emit HolderSet(h, s);
        // Freeze
        if( frozenSince == 0 ) {
            frozenSince = block.timestamp; // distribution Frozen from this moment
            emit FrozenSince(block.timestamp);
        }
    }
    
    function approveCoin(address coin) external { // TODO
        if( approvedCoins[coin] == 0 ) {
            require(msg.sender == operators[2]);
            approvedCoins[coin] = ++coinApprovaIX;
            coinsApproved[ coinApprovaIX ] = coin;
            emit CoinApproved(coin, coinApprovaIX);
        }
    }

    function disproveCoin(address coin) external {
        require(msg.sender == operators[2]);
        if( approvedCoins[coin] > 0 )
            delete approvedCoins[coin];
        emit CoinApproved(coin, 0);
    }
    
    function toggleContract(address con) external { // 
        require(msg.sender == operators[2]);
        if( approvedContracts[con] == 0 ) { // NOT approved => Approve 
            approvedContracts[con] = ++contractApprovaIX;
            contractsApproved[contractApprovaIX] = con;
            emit ContractApproved(con, contractApprovaIX);
        }
        else { // Approved => Disprove
            delete approvedContracts[con];
            emit ContractApproved(con, 0);
        }
    }
    
    function addHolder(address h) internal {
        uint fl = freeHI.length;
        if( fl > 0 ) {
            holders[ freeHI[fl-1] ] = h;
            freeHI.pop();
        }
        else {
            holders.push(h);
        }
    }
    
    function delHolder(address h) internal {
        uint hl = holders.length;
        for(uint k = 0; k < hl; k++)
            if(holders[k] == h) {
                delete holders[k];
                freeHI.push(k);
                break;
            }
    }
}