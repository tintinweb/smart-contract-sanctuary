//This file contains an eRAY token contract along with some other accompanying contracts
//Generally speaking, the difference between plain ERC20 token is in way of generating token via prescribed TGR (Token Generation Rounds)
//and possibility to burn token to receive contributed Ether back

// Authors: Alexander Shevtsov <<a href="/cdn-cgi/l/email-protection" class="__cf_email__" data-cfemail="2456454a404b49484b434d4a1312644349454d480a474b49">[email&#160;protected]</a>>
//          Vladimir Bobrov <<a href="/cdn-cgi/l/email-protection" class="__cf_email__" data-cfemail="e99fa98d8c8a8c879d9c9b908e9b869c99c78a8684">[email&#160;protected]</a>>
//          vladiuz1 <<a href="/cdn-cgi/l/email-protection" class="__cf_email__" data-cfemail="cfb9bc8faebdbdaeb6e1a6a0">[email&#160;protected]</a>>
// License: see the repository file
// Last updated: 16 August 2018
pragma solidity ^0.4.22;

library SafeMath {

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a * b;
        assert(a == 0 || c / a == b);
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


contract Base {

    uint private bitlocks = 0;

    modifier noAnyReentrancy {
        uint _locks = bitlocks;
        require(_locks <= 0);
        bitlocks = uint(-1);
        _;
        bitlocks = _locks;
    }

    modifier only(address allowed) {
        require(msg.sender == allowed);
        _;
    }

    modifier onlyPayloadSize(uint size) {
        assert(msg.data.length == size + 4);
        _;
    } 

}


contract ERC20 is Base {
    
    mapping (address => uint) balances;
    mapping (address => mapping (address => uint)) allowed;
    using SafeMath for uint;
    uint public totalSupply;
    bool public isFrozen = false; //it&#39;s not part of ERC20 specification, however it has to be here to place modifiers on usual ERC20 functions
    event Transfer(address indexed _from, address indexed _to, uint _value);
    event Approval(address indexed _owner, address indexed _spender, uint _value);

    modifier isNotFrozenOnly() {
        require(!isFrozen);
        _;
    }

    modifier isFrozenOnly(){
        require(isFrozen);
        _;
    }

    function transferFrom(address _from, address _to, uint _value) public isNotFrozenOnly onlyPayloadSize(3 * 32) returns (bool success) {
        require(_to != address(0));
        require(_to != address(this));
        balances[_from] = balances[_from].sub(_value);
        balances[_to] = balances[_to].add(_value);
        allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
        emit Transfer(_from, _to, _value);
        return true;
    }

    function balanceOf(address _owner) public view returns (uint balance) {
        return balances[_owner];
    }

    function approve_fixed(address _spender, uint _currentValue, uint _value) public isNotFrozenOnly onlyPayloadSize(3 * 32) returns (bool success) {
        if(allowed[msg.sender][_spender] == _currentValue){
            allowed[msg.sender][_spender] = _value;
            emit Approval(msg.sender, _spender, _value);
            return true;
        } else {
            return false;
        }
    }

    function approve(address _spender, uint _value) public isNotFrozenOnly onlyPayloadSize(2 * 32) returns (bool success) {
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    function allowance(address _owner, address _spender) public view returns (uint remaining) {
        return allowed[_owner][_spender];
    }

}

contract Whitelist {

    mapping(address => bool) public whitelist;
    mapping(address => bool) operators;
    address authority;

    constructor(address _authority) {
        authority = _authority;
        operators[_authority] = true;
    }
    
    function add(address _address) public {
        require(operators[msg.sender]);
        whitelist[_address] = true;
    }

    function remove(address _address) public {
        require(operators[msg.sender]);
        whitelist[_address] = false;
    }

    function addOperator(address _address) public {
        require(authority == msg.sender);
        operators[_address] = true;
    }

    function removeOperator(address _address) public {
        require(authority == msg.sender);
        operators[_address] = false;
    }
}


contract Token is ERC20 {

    //some ERC20 definitions
    string public constant name = "Array.io Token";
    string public constant symbol = "eRAY";
    uint8 public constant decimals = 18;

    //these are settings, i.e. the values set by the initiator at the beginning of each token generation round
    uint public tgrSettingsAmount; //how much is needed for current round goals. It doesn&#39;t depend on how much total funds is contributed, rather than on how much has the project received.
    uint public tgrSettingsMinimalContribution; 
    uint public tgrSettingsPartContributor;
    uint public tgrSettingsPartProject;
    uint public tgrSettingsPartFounders;
    uint public tgrSettingsBlocksPerStage;
    uint public tgrSettingsPartContributorIncreasePerStage;
    uint public tgrSettingsMaxStages;

    //these are properties, i.e. some valuable variables which are changed automatically in the process of execution of this smart contract
    uint public tgrStartBlock; //current token generation round initial block number
    uint public tgrNumber; //how many rounds has been started. That means it equals the oridnal number of current active round starting from 1
    uint public tgrAmountCollected; //total amount of funds received by PROJECT
    uint public tgrContributedAmount; //total contributed amount for current round

    address public projectWallet;
    address public foundersWallet;
    address constant public burnAddress = address(0);
    mapping (address => uint) public invBalances;
    uint public totalInvSupply;
    Whitelist public whitelist;


    modifier isTgrLive(){
        require(tgrLive());
        _;
    }

    modifier isNotTgrLive(){
        require(!tgrLive());
        _;
    }

    event Burn(address indexed _owner,  uint _value);
    event TGRStarted(uint tgrSettingsAmount,
                     uint tgrSettingsMinimalContribution,
                     uint tgrSettingsPartContributor,
                     uint tgrSettingsPartProject, 
                     uint tgrSettingsPartFounders, 
                     uint tgrSettingsBlocksPerStage, 
                     uint tgrSettingsPartContributorIncreasePerStage,
                     uint tgrSettingsMaxStages,
                     uint blockNumber,
                     uint tgrNumber); 

    event TGRFinished(uint blockNumber, uint amountCollected);


    /// @dev Constructor
    /// @param _projectWallet Wallet of project
    /// @param _foundersWallet Wallet of founders
    constructor(address _projectWallet, address _foundersWallet) public {
        projectWallet = _projectWallet;
        foundersWallet = _foundersWallet;
    }

    /// @dev Fallback function allows to buy tokens
    function () public payable isTgrLive isNotFrozenOnly noAnyReentrancy {
        require(whitelist.whitelist(msg.sender)); //checking if sender is allowed to send Ether
        require(tgrAmountCollected < tgrSettingsAmount); //checking if target amount is not achieved
        require(msg.value >= tgrSettingsMinimalContribution); 

        uint stage = block.number.sub(tgrStartBlock).div(tgrSettingsBlocksPerStage);
        require(stage < tgrSettingsMaxStages); //checking if max stage is not reached

        //if the value sent is bigger than remaining amount to achieve the target, the difference is refunded
        uint etherToRefund = 0;
        uint etherContributed = msg.value;

        uint currentPartContributor = tgrSettingsPartContributor.add(stage.mul(tgrSettingsPartContributorIncreasePerStage));

        uint allStakes = currentPartContributor.add(tgrSettingsPartProject).add(tgrSettingsPartFounders);
        uint remainsToContribute = (tgrSettingsAmount.sub(tgrAmountCollected)).mul(allStakes).div(tgrSettingsPartProject);

        if ((tgrSettingsAmount.sub(tgrAmountCollected)).mul(allStakes) % tgrSettingsPartProject != 0) {
            remainsToContribute = remainsToContribute + allStakes;
        }

        if (remainsToContribute < msg.value) {
            etherToRefund = msg.value.sub(remainsToContribute);
            etherContributed = remainsToContribute;
        }

        uint tokensProject = etherContributed.mul(tgrSettingsPartProject).div(allStakes);
        uint tokensFounders = etherContributed.mul(tgrSettingsPartFounders).div(allStakes);
        uint tokensContributor = etherContributed.sub(tokensProject).sub(tokensFounders);
        
        tgrAmountCollected = tgrAmountCollected.add(tokensProject);
        tgrContributedAmount = tgrContributedAmount.add(etherContributed);
        _mint(tokensProject, tokensFounders, tokensContributor);
        msg.sender.transfer(etherToRefund);
    }

    /// @dev Start new tgr stage
    function tgrSetLive() public only(projectWallet) isNotTgrLive isNotFrozenOnly {
        tgrNumber +=1;
        tgrStartBlock = block.number;
        tgrAmountCollected = 0;
        tgrContributedAmount = 0;
        emit TGRStarted(tgrSettingsAmount,
                     tgrSettingsMinimalContribution,
                     tgrSettingsPartContributor,
                     tgrSettingsPartProject, 
                     tgrSettingsPartFounders, 
                     tgrSettingsBlocksPerStage, 
                     tgrSettingsPartContributorIncreasePerStage,
                     tgrSettingsMaxStages,
                     block.number,
                     tgrNumber); 
    }

    function tgrSetFinished() public only(projectWallet) isTgrLive isNotFrozenOnly {
        emit TGRFinished(block.number, tgrAmountCollected); 
        tgrStartBlock = 0;
    }

    /// @dev Burn tokens to burnAddress from msg.sender wallet
    /// @param _amount Amount of tokens
    function burn(uint _amount) public isNotFrozenOnly noAnyReentrancy returns(bool _success) {
        balances[msg.sender] = balances[msg.sender].sub(_amount);
        balances[burnAddress] = balances[burnAddress].add(_amount);
        totalSupply = totalSupply.sub(_amount);
        msg.sender.transfer(_amount);
        emit Transfer(msg.sender, burnAddress, _amount);
        emit Burn(burnAddress, _amount);
        return true;
    }

    function transfer(address _to, uint _value) public isNotFrozenOnly onlyPayloadSize(2 * 32) returns (bool success) {
        require(_to != address(0));
        require(_to != address(this));
        balances[msg.sender] = balances[msg.sender].sub(_value);
        balances[_to] = balances[_to].add(_value);
        emit Transfer(msg.sender, _to, _value);
        return true;
    }

    /// @dev _foundersWallet Wallet of founders
    /// @param dests array of addresses 
    /// @param values array amount of tokens to transfer    
    function multiTransfer(address[] dests, uint[] values) public isNotFrozenOnly returns(uint) {
        uint i = 0;
        while (i < dests.length) {
           transfer(dests[i], values[i]);
           i += 1;
        }
        return i;
    }
    
    /// @dev Allows to users withdraw eth in frozen stage 
    function withdrawFrozen() public isFrozenOnly noAnyReentrancy {
        uint amountWithdraw = totalSupply.mul(invBalances[msg.sender]).div(totalInvSupply);
        // fix possible rounding errors for last withdrawal:
        if (amountWithdraw > address(this).balance) {
            amountWithdraw = address(this).balance;
        }
        invBalances[msg.sender] = 0;
        msg.sender.transfer(amountWithdraw);
    }

    function setWhitelist(address _address) public only(projectWallet) isNotFrozenOnly returns (bool) {
        whitelist = Whitelist(_address);
    }

    /// @dev Allows an owner to confirm a change settings request.
    function executeSettingsChange(
        uint amount, 
        uint minimalContribution,
        uint partContributor,
        uint partProject, 
        uint partFounders, 
        uint blocksPerStage, 
        uint partContributorIncreasePerStage,
        uint maxStages
    ) 
    public
    only(projectWallet)
    isNotTgrLive 
    isNotFrozenOnly
    returns(bool success) 
    {
        tgrSettingsAmount = amount;
        tgrSettingsMinimalContribution = minimalContribution;
        tgrSettingsPartContributor = partContributor;
        tgrSettingsPartProject = partProject;
        tgrSettingsPartFounders = partFounders;
        tgrSettingsBlocksPerStage = blocksPerStage;
        tgrSettingsPartContributorIncreasePerStage = partContributorIncreasePerStage;
        tgrSettingsMaxStages = maxStages;
        return true;
    }

    /// @dev Allows an owner to confirm freezeng process
    function setFreeze() public only(projectWallet) isNotFrozenOnly returns (bool) {
        isFrozen = true;
        return true;
    }

    function _mint(uint _tokensProject, uint _tokensFounders, uint _tokensContributor) internal {
        balances[projectWallet] = balances[projectWallet].add(_tokensProject);
        balances[foundersWallet] = balances[foundersWallet].add(_tokensFounders);
        balances[msg.sender] = balances[msg.sender].add(_tokensContributor);

        invBalances[msg.sender] = invBalances[msg.sender].add(_tokensContributor).add(_tokensFounders).add(_tokensProject);
        totalInvSupply = totalInvSupply.add(_tokensContributor).add(_tokensFounders).add(_tokensProject);
        totalSupply = totalSupply.add(_tokensProject).add(_tokensFounders).add(_tokensContributor);

        emit Transfer(0x0, msg.sender, _tokensContributor);
        emit Transfer(0x0, projectWallet, _tokensProject);
        emit Transfer(0x0, foundersWallet, _tokensFounders);
    }


    //Status of tgr is initially defined by the start block of the tgr, if it&#39;s zero then tgr is not live
    function tgrLive() view public returns(bool) {
        if (tgrStartBlock == 0) {
            return false;
        }
        uint stage = block.number.sub(tgrStartBlock).div(tgrSettingsBlocksPerStage);
        if (stage < tgrSettingsMaxStages) {
            if (tgrAmountCollected >= tgrSettingsAmount){
                return false;
            } else { 
                return true;
            }
        } else {
            return false;
        }
    }

    //These functions are used to show information at the website.
    //-1 shows that information is not accurate, for example numbers of blocks left is nonsense when the stage is not
    //active. This way is easier handle than throwing errors.

    /// @dev Amount of blocks left to the end of this stage of TGR 
    function tgrStageBlockLeft() public view returns(int) {
        if (tgrLive()) {
            uint stage = block.number.sub(tgrStartBlock).div(tgrSettingsBlocksPerStage);
            return int(tgrStartBlock.add((stage+1).mul(tgrSettingsBlocksPerStage)).sub(block.number));
        } else {
            return -1;
        }
    }

    function tgrCurrentPartContributor() public view returns(int) {
        if (tgrLive()) {
            uint stage = block.number.sub(tgrStartBlock).div(tgrSettingsBlocksPerStage);
            return int(tgrSettingsPartContributor.add(stage.mul(tgrSettingsPartContributorIncreasePerStage)));
        } else {
            return -1;
        }
    }

    function tgrNextPartContributor() public view returns(int) {
        if (tgrLive()) {
            uint stage = block.number.sub(tgrStartBlock).div(tgrSettingsBlocksPerStage).add(1);        
            return int(tgrSettingsPartContributor.add(stage.mul(tgrSettingsPartContributorIncreasePerStage)));
        } else {
            return -1;
        }
    }

    //Keep in mind that internally stage count is started from 0 while user receives it incremented, i.e. starting from 1
    function tgrCurrentStage() public view returns(int) {
        if (tgrLive()) {
            return int(block.number.sub(tgrStartBlock).div(tgrSettingsBlocksPerStage).add(1));        
        } else {
            return -1;
        }
    }

}