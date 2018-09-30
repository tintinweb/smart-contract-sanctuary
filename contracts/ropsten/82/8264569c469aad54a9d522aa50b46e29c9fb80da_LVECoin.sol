pragma solidity ^0.4.24;

// *-----------------------------------------------------------------------*
//       __ _    ________   __________  _____   __
//      / /| |  / / ____/  / ____/ __ \/  _/ | / /
//     / / | | / / __/    / /   / / / // //  |/ / 
//    / /__| |/ / /___   / /___/ /_/ // // /|  /  
//   /_____/___/_____/   \____/\____/___/_/ |_/  
// *-----------------------------------------------------------------------*


/**
 * @title SafeMath
 */
library SafeMath {

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        assert(c / a == b);
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a / b;
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        assert(c >= a);
        return c;
    }
}


/**
 * @title Ownable
 * @ multiSig
 */
contract Ownable {

    event SubmitPrps(ProposalType indexed _prpsType);
    event SignPrps(uint256 indexed _prpsIndex, ProposalType indexed _prpsType, address indexed _owner);

    // owner proposal type enum
    enum ProposalType {
        pause,
        unpause,
        freeze,
        unfreeze 
    }
    // owner proposal
    struct Proposal {
        ProposalType prpsType;
        mapping(address => bool) signed;
        bool finalized;
    }
    // require sign owner number
    uint256 requiredSignNum;
    // all owner address
    address[] public owners;
    // owner proposal list
    Proposal[] public proposals;
    // is owner mapping
    mapping(address => bool) public isOwnerMap;

    constructor() public{
    }


    // is owner
    modifier isOwner{
        require(isOwnerMap[msg.sender], "");
        _;
    }
    // proposal is exist
    modifier isPrpsExists(uint256 _prpsIndex) {
        require(_prpsIndex >= 0, "");
        require(_prpsIndex < proposals.length, "");
        _;
    }
    // is most owner sign proposal
    modifier multiSig(uint256 _prpsIndex) {
        // is more than half(多數決)
        require(signOwnerCount(_prpsIndex) >= requiredSignNum, "");
        // proposal is not finalized
        require(proposals[_prpsIndex].finalized == false, "");
        _;
    }


    // any owner submit not certified proposal
    function submitProposal(ProposalType _prpsType) public isOwner {
        Proposal memory _proposal;
        _proposal.prpsType = _prpsType;
        _proposal.finalized = false;
        proposals.push(_proposal);
        emit SubmitPrps(_prpsType);
    }

    // owner sign proposal
    function signProposal(uint256 _prpsIndex) public isOwner isPrpsExists(_prpsIndex){
        if (proposals[_prpsIndex].signed[msg.sender] != true) {
            proposals[_prpsIndex].signed[msg.sender] = true;
            emit SignPrps(_prpsIndex, proposals[_prpsIndex].prpsType, msg.sender);
        }
    }

    // get proposal owner sign number(多數決)
    function signOwnerCount(uint256 _prpsIndex) public view isPrpsExists(_prpsIndex) returns(uint256) {
        uint256 signedCount = 0;
        for(uint i = 0; i < owners.length; i++) {
            if(proposals[_prpsIndex].signed[owners[i]]){
                signedCount++;
            }
        }
        return signedCount;
    }

    // proposal count nums
    function geProposalCount() public view returns(uint256){
        return proposals.length;
    }

    // get proposal sign status info
    function geProposalInfo(uint256 _prpsIndex) public view isPrpsExists(_prpsIndex) returns(ProposalType _prpsType, uint256 _signedCount, bool _isFinalized){

        Proposal memory _proposal = proposals[_prpsIndex];
        uint256 signCount = signOwnerCount(_prpsIndex);
        return (_proposal.prpsType, signCount, _proposal.finalized);
    }


}



/**
 * @title Pausable
 */
contract Pausable is Ownable {

    event Pause();
    event Unpause();

    bool public paused = false;

    modifier whenNotPaused {
        require(!paused, "");
        _;
    }
    modifier whenPaused {
        require(paused, "");
        _;
    }

    // Pause contract   
    function pause(uint256 _prpsIndex) public isOwner whenNotPaused isPrpsExists(_prpsIndex) multiSig(_prpsIndex) returns (bool) {
        // is right enum proposalType
        require(proposals[_prpsIndex].prpsType == ProposalType.pause, "");

        paused = true;
        proposals[_prpsIndex].finalized = true;
        emit Pause();
        return true;
    }

    // Unpause contract
    function unpause(uint256 _prpsIndex) public isOwner whenPaused isPrpsExists(_prpsIndex) multiSig(_prpsIndex) returns (bool) {
        // is right enum proposalType
        require(proposals[_prpsIndex].prpsType == ProposalType.unpause, "");

        paused = false;
        proposals[_prpsIndex].finalized = true;
        emit Unpause();
        return true;
    }

}


/**
 * @title ERC20 interface
 */
contract ERC20 {
    event Transfer(address indexed _from, address indexed _to, uint256 _amount);
    // _from: _owner _to: _spender
    event Approval(address indexed _from, address indexed _to, uint256 _amount);
    function totalSupply() public view returns (uint256);
    function balanceOf(address _owner) public view returns (uint256);
    function transfer(address _to, uint256 _value) public returns (bool);
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool);
    function approve(address _spender, uint256 _value) public returns (bool);
    function allowance(address _owner, address _spender) public view returns (uint256);
}



/**
 * @title ERC20Token
 */
contract ERC20Token is ERC20 {

    using SafeMath for uint256;

    mapping(address => uint256) balances;
    mapping(address => mapping (address => uint256)) allowed;
    uint256 public totalToken;

    function totalSupply() public view returns (uint256) {
        return totalToken;
    }

    function balanceOf(address _owner) public view returns (uint256) {
        require(_owner != address(0), "");
        return balances[_owner];
    }

    // Transfer token by internal
    function _transfer(address _from, address _to, uint256 _value) internal {
        require(_to != address(0), "");
        require(balances[_from] >= _value, "");

        balances[_from] = balances[_from].sub(_value);
        balances[_to] = balances[_to].add(_value);
        emit Transfer(_from, _to, _value);
    }

    function transfer(address _to, uint256 _value) public returns (bool) {
        require(_to != address(0), "");
        _transfer(msg.sender, _to, _value);
        return true;
    }
    
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool){
        require(_from != address(0), "");
        require(_to != address(0), "");
        require(_value > 0, "");
        require(balances[_from] >= _value, "");
        require(allowed[_from][msg.sender] >= _value, "");

        balances[_from] = balances[_from].sub(_value);
        balances[_to] = balances[_to].add(_value);
        allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
        emit Transfer(_from, _to, _value);
        return true;
    }

    function approve(address _spender, uint256 _value) public returns (bool){
        require(_spender != address(0), "");
        require(_value > 0, "");
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    function allowance(address _owner, address _spender) public view returns (uint256){
        require(_owner != address(0), "");
        require(_spender != address(0), "");
        return allowed[_owner][_spender];
    }

}


/**
 * @title LVECoin
 */
contract LVECoin is ERC20Token, Pausable {

    string public  constant name        = "LVECoin";
    string public  constant symbol      = "LVE";
    uint256 public constant decimals    = 18;
    // issue all token
    uint256 private initialToken        = 2000000000 * (10 ** decimals);
    
    // _to: _freezeAddr
    event Freeze(address indexed _to);
    // _to: _unfreezeAddr
    event Unfreeze(address indexed _to);
    event WithdrawalEther(address indexed _to, uint256 _amount);
    
    // freeze account mapping
    mapping(address => bool) public freezeAccountMap;  
    // wallet Address
    address private walletAddr;

    constructor(address[] _initOwners, address _walletAddr) public{
        require(_initOwners.length == 3, "");
        require(_walletAddr != address(0), "");

        // init owners
        requiredSignNum = _initOwners.length.div(2).add(1);
        owners = _initOwners;
        for(uint i = 0; i < _initOwners.length; i++) {
            isOwnerMap[_initOwners[i]] = true;
        }

        totalToken = initialToken;
        walletAddr = _walletAddr;
        balances[msg.sender] = totalToken;
        emit Transfer(0x0, msg.sender, totalToken);
    }



    // is freezeable account
    modifier freezeable(address _addr) {
        require(_addr != address(0), "");
        require(!freezeAccountMap[_addr], "");
        _;
    }

    function transfer(address _to, uint256 _value) public whenNotPaused freezeable(msg.sender) returns (bool) {
        require(_to != address(0), "");
        return super.transfer(_to, _value);
    }
    function transferFrom(address _from, address _to, uint256 _value) public whenNotPaused freezeable(msg.sender) returns (bool) {
        require(_from != address(0), "");
        require(_to != address(0), "");
        return super.transferFrom(_from, _to, _value);
    }
    function approve(address _spender, uint256 _value) public whenNotPaused freezeable(msg.sender) returns (bool) {
        require(_spender != address(0), "");
        return super.approve(_spender, _value);
    }


    // freeze account
    function freezeAccount(address _freezeAddr, uint256 _prpsIndex) public isOwner isPrpsExists(_prpsIndex) multiSig(_prpsIndex) returns (bool) {
        require(_freezeAddr != address(0), "");
        // is right enum proposalType
        require(proposals[_prpsIndex].prpsType == ProposalType.freeze, "");

        freezeAccountMap[_freezeAddr] = true;
        // proposals execute over
        proposals[_prpsIndex].finalized = true;
        emit Freeze(_freezeAddr);
        return true;
    }
    
    // unfreeze account
    function unfreezeAccount(address _freezeAddr, uint256 _prpsIndex) public isOwner isPrpsExists(_prpsIndex) multiSig(_prpsIndex) returns (bool) {
        require(_freezeAddr != address(0), "");
        // is right enum proposalType
        require(proposals[_prpsIndex].prpsType == ProposalType.unfreeze, "");

        freezeAccountMap[_freezeAddr] = false;
        // proposals execute over
        proposals[_prpsIndex].finalized = true;
        emit Unfreeze(_freezeAddr);
        return true;
    }

    // if send ether then send ether to owner
    function() public payable {
        require(msg.value > 0, "");
        walletAddr.transfer(msg.value);
        emit WithdrawalEther(walletAddr, msg.value);
    }

}