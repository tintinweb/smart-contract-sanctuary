/**
 *Submitted for verification at Etherscan.io on 2021-05-06
*/

/**
 *Submitted for verification at BscScan.com on 2021-04-09
*/

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

/*
    RH Style Guide:
        ContractsAndDataStructures
        member_variables_
        _argument_variables
        local_variable
        struct_member_variable
        functionNames
        SOME_CONSTANT
        
        
        lhs_ = _rhs;
        
        _lhs == rhs_
*/
abstract
contract OracleCallable {
    
    address private oracle_key_;
    
    event OracleKeyChanged(address indexed _oracle_key);
    
    constructor (address _oracle_key) {
        oracle_key_ = _oracle_key;
        emit OracleKeyChanged(_oracle_key);
    }    
    
    modifier onlyOracle() {
        require(oracle_key_ == msg.sender, "Caller is not the oracle");
        _;
    }    
    
    function changeOracleKeyInternal(address _oracle_key) internal
    {
        require(_oracle_key != address(0), "New oracle is the zero address");
        emit OracleKeyChanged(_oracle_key);
        oracle_key_ = _oracle_key;
    }
    
    function changeOracleKey(address _oracle_key) external onlyOracle returns (bool success) 
    {
        changeOracleKeyInternal(_oracle_key);
        return true;
    }   
    
    function getOracleKey() view public returns (address)
    {
        return oracle_key_;
    }
}


abstract
contract PigeonReceive is OracleCallable {
    
    event PigeonCallable (address _oracleKey);
    
    event PigeonArrived (
         uint256  _source_chain_id,    uint256 _source_contract_id,     
         uint256  _source_block_no,    uint256  _source_confirmations,   uint256 _source_txn_hash,
         uint256 _source_topic0,      uint256 _source_topic1,          uint256 _source_topic2,
         uint256 _source_topic3,      uint256 _source_topic4,          uint256 _source_topic5
    );

    constructor (address _oracleKey) OracleCallable (_oracleKey) 
    {
        emit PigeonCallable(_oracleKey);
    }

    function pigeonArrive (
        uint256  _source_chain_id,    uint256 _source_contract_id,
        uint256  _source_block_no,    uint256  _source_confirmations,   uint256 _source_txn_hash,
        uint256 _topic0, uint256 _topic1, uint256 _topic2, uint256 _topic3, uint256 _topic4, uint256 _topic5
    ) onlyOracle external virtual returns (bool success)
    {
        emit PigeonArrived(
           _source_chain_id, _source_contract_id,
           _source_block_no, _source_confirmations, _source_txn_hash,
           _topic0, _topic1, _topic2, _topic3, _topic4, _topic5);
        return true;
    }
    
}

abstract
contract PigeonInterface {
    event PigeonCall(
        uint256 _source_txn_hash, uint256 _source_event_id,
        uint256 _dest_chain_id,  uint256 _dest_contract_id
    );
    
    function pigeonSend(
        uint256 _source_txn_hash,    uint256 _source_event_id,
        uint256 _dest_chain_id,      uint256 _dest_contract_id) external virtual payable returns (bool success);
 
    function pigeonCost(uint256 _dest_chain_id) external view virtual returns (uint256 pigeon_call_cost);

    function setPigeonCost(uint256 _dest_chain_id, uint256 cost) external virtual returns (bool success);
    
    function chainId() external view virtual returns (uint256);
    
    function getPigeonOracleKey() view virtual public returns (address);

}

abstract
contract EIP20Interface {
    function total_supply()
        external view virtual returns (uint256);
    function balanceOf(address _owner)
        external view virtual returns (uint256 balance);
    function allowance(address _owner, address _spender)
        external view virtual returns (uint256 remaining);

    function transfer(address _to, uint256 _value)
        external virtual returns (bool success);
    function transferFrom(address _from, address _to, uint256 _value)
        external virtual returns (bool success);
    function approve(address _spender, uint256 _value)
        external virtual returns (bool success);

    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}


abstract
contract
UniwarpVaultInterface is EIP20Interface {
    uint256 constant VAULTED_EVENT_ID = 0x202c84ded448d8f25e219522de3b98e78675c6e8aeb88c805908fbc6fe6094c5;
    event Vaulted (uint256 _vaulter, uint256 _dest_chain_id, uint256 _amount);
    address constant public OFF_CHAIN = address(0xd15Ab1ed00000000000000000000000000000000);

    function vaultFee(uint256 _dest_chain_id) view virtual external returns (uint256);
    function vault(uint256 _dest_chain_id, uint256 _amount) virtual external payable returns (bool success);
    function vaultFrom(address _from, uint256 _dest_chain_id, uint256 _amount) virtual external payable returns (bool success);
    function chainId() view virtual external returns (uint256 _chain_id);
}

abstract
contract 
UniwarpDAOInterface {
    struct Proposal
    {
        address proposer; // the proposer is required to also action the proposal at the end, thus they are responsible for gas fees
        uint256 operation;  // see validateProposal()
        uint256 chain_id;             
        uint256 operand; // address or other operand to the vote, e.g. tokens_per_proposal when operation == 7
        uint256 expiry_block; // block number when this proposal can be actioned
        uint256 cancel_block;  // block number when this proposal can be cancelled
        bytes32 explain1;
        bytes32 explain2;
        uint256 lockedTokens;
        uint16 yay;    // "yes" votes
        uint16 nay;    // "no" votes
    }
    
    // this is like a blackhole address but it's a disabled holding location for coins that are currently 'off chain' (i.e. on a different chain after a vault event)
            
    uint256 constant PROPOSAL_ACTION_EVENT_ID = 0x3beb9a573715f796038dda8fdd3763a415c709081cb3cf432e48ff8b7ec600db;
    event ProposalActioned (uint256 _operation, uint256 _operand_chain_id, uint256 _operand);


    function viewProposal(uint256 _proposal_id) view virtual external returns (Proposal memory proposal);

    function validateProposal(uint256 _operation, uint256 _operand_chain_id, uint256 _operand) virtual view public returns (bool success);
    
    function redeemVoteTokens(uint256 _proposal_id) virtual external returns(bool success);

    function actionProposal(uint256 _proposal_id)  virtual external payable returns (bool success);

    function actionProposalCost() view virtual external returns (uint256 amount);

    function propose(uint256 _operation, uint256 _operand_chain_id, uint256 _operand, bytes32 _explain1, bytes32 _explain2) virtual external returns (uint256);

    function cancelProposal(uint256 _proposal_id) virtual external returns (bool success);

    function vote(uint256 _proposal_id, uint16 _yay, uint16 _nay) virtual external returns (bool success);

    function getVotingChain() external view virtual returns (uint256 _chain_id);

    function isVotingChain() external view virtual returns(bool _is_voting);

    function isDisabled(uint256 _chain_id)  external view virtual returns(bool _is_disabled);

    function getProposalCount() external view virtual returns (uint256);

    function getTokensPerVote() external view virtual returns (uint256);

    function getTokensPerProposal() external view virtual returns (uint256);

    function getChainCount() external view virtual returns (uint256);

    function getPigeonAddress() external view virtual  returns (address pigeon);
    
    function getProposalExpiry() external view virtual returns (uint256 expiry);


}

contract Uniwarp is PigeonReceive, UniwarpVaultInterface, UniwarpDAOInterface {



    function getProposalExpiry() external view override returns (uint256 expiry)
    {
        return voting_block_expiry_;
    }

    function isDisabled(uint256 _chain_id)  external view override returns(bool _is_disabled)
    {
        return disabled_chains_[_chain_id];
    }

    function getPigeonAddress() external view override returns (address pigeon)
    {
        return pigeon_address_;
    }

    function getProposalCount() external view override returns (uint256)
    {
        return proposal_count_;
    }

    function getTokensPerVote() external view override returns (uint256)
    {
        return tokens_per_vote_;
    }

    function getTokensPerProposal() external view override returns (uint256)
    {
        return tokens_per_proposal_;
    }

    function getChainCount() external view override returns (uint256)
    {
        return chain_count_;
    }


    function getVotingChain() external view override returns (uint256 _chain_id)
    {
        return voting_chain_id_;
    }
    
    function isVotingChain() external view override returns(bool _is_voting)
    {
        return voting_chain_id_ == chain_id_;
    }

    function chainId() view override external returns (uint256 _chain_id)
    {
        return chain_id_;
    }

    mapping(bytes32 => bool) private alreadyArrived_;

    function pigeonArrive (
        uint256  _source_chain_id,    uint256 _source_contract_id,
        uint256  _source_block_no,    uint256  _source_confirmations,   uint256 _source_txn_hash,
        uint256 _topic0, uint256 _topic1, uint256 _topic2, uint256 _topic3, uint256 _topic4, uint256 _topic5)
        onlyOracle checkDeleted external override returns (bool success)
    {
        
        require(_topic0 == VAULTED_EVENT_ID || _topic0 == PROPOSAL_ACTION_EVENT_ID, "Pigeon received but not a valid event type.");
        require(uniwarp_contracts_[_source_chain_id] == _source_contract_id, "Received pigeon from unknown contract...");
        
        bytes32 hash = keccak256(abi.encodePacked(_source_chain_id, _source_txn_hash, _topic0, _topic1, _topic2, _topic3));
        require(!alreadyArrived_[hash], "Already processed this pigeon");
        alreadyArrived_[hash] = true;
        
        if (_topic0 == VAULTED_EVENT_ID)
        {

            //require(_topic1 >> 96 == 0x0, "Invalid vault account on incoming pigeon");        
            address vault_owner = address(uint160(_topic1));
            require(_topic2 == chain_id_, "Pigeon received for wrong chainid!");
            uint256 vault_amount = _topic3;
        
            require(vault_amount > 0, "Invalid pigeon (1)!");
            require(vault_owner != address(0x0), "Invalid pigeon (2)!");
            require(vault_amount <= balances_[OFF_CHAIN], "Offchain invariant failed!!!");
        
            uint256 old_balance = balances_[OFF_CHAIN];
            balances_[OFF_CHAIN] -= vault_amount;
            require(old_balance > balances_[OFF_CHAIN], "Internal error (1)");
        
            old_balance = balances_[vault_owner];
            balances_[vault_owner] += vault_amount;
            require(balances_[vault_owner] > old_balance, "Internal error (2)");
            
            
            emit Transfer(OFF_CHAIN, vault_owner, vault_amount);
        } 
        else if (_topic0 == PROPOSAL_ACTION_EVENT_ID)
            actionProposalInternal(_topic1, _topic2, _topic3, false);

        emit PigeonArrived(
           _source_chain_id, _source_contract_id,
           _source_block_no, _source_confirmations, _source_txn_hash,
           _topic0, _topic1, _topic2, _topic3, _topic4, _topic5);

        return true;
    }



    uint256 constant private MAX_UINT256 = 2**256 - 1;

    
    mapping (address => uint256)  public balances_;
    mapping (address => mapping (address => uint256)) public allowed_;
    

    uint256 public chain_id_;
    uint256 public chain_count_;
    mapping (uint256 => uint256) public chain_ids_;
    mapping (uint256 => uint256) public uniwarp_contracts_;             // chain_id -> contract address (may not be an ethereum-based chain so address is uint256)
    mapping (uint256 => mapping (address => uint256)) public votes_;    // proposal_id => voter => lockedTokens

    mapping (uint256 => bool) public disabled_chains_;
    
    uint256 public total_supply_;
    address public pigeon_address_;
    
    mapping (uint256 => Proposal) public proposals_;

    uint256 public proposal_count_;
    uint256 public voting_chain_id_;
    uint256 public voting_block_expiry_;
    uint256 public tokens_per_vote_ = 100000000000000000000000;
    uint256 public tokens_per_proposal_ = 1000000000000000000000000;
        
    bool deleted_ = false;      // if this contract copy has been disabled (deleted) either because it was "removed" from the chain or changed to a new contract then refuse to do anything

    modifier checkDeleted()
    {
        require(!deleted_, "This version of uniwarp on this chain has been deleted.");
        _;
    }
    
    modifier checkDisabled()
    {
        require(!disabled_chains_[chain_id_], "This version of uniwarp on this chain has been disabled.");
        _;
    }
    
    function viewProposal(uint256 _proposal_id) view override external returns (Proposal memory proposal)
    {
        require(proposals_[_proposal_id].operation > 0, "Invalid proposal");
        return proposals_[_proposal_id];
    }
    
    // sanity check the parameters to a proposal
    function validateProposal(uint256 _operation, uint256 _operand_chain_id, uint256 _operand) override view public returns (bool success)
    {
        // 1 == add chain, 2 == remove chain, 3 == change pigeon address for a specified chain (for pigeonSend),
        // 4 = propose new voting contract,   5 = propose new proposal block expiry,
        // 6 = tokens_per_vote, 7 = tokens_per_proposal, 8 = change pigeon oracle key. 9 = change contract id on a chain, 10 = disable a chain (they can send off the chain but not receive)
        // 11 = enable chain

        require(_operation > 0 && _operation < 12, "Invalid proposed operation.");

        if (_operation == 9) // change contract id on an existing chain
        {
            require(uniwarp_contracts_[_operand_chain_id] != 0x0, "Can only change a chain that exists");
            require(_operand != 0x0, "Can't change to null contract");
        }
        else if (_operation == 1) // add chain
        {
            require(_operand_chain_id != chain_id_, "Cannot add this chain... it's already on this chain!");
            require(uniwarp_contracts_[_operand_chain_id] == 0x0, "Cannot add chain, already added!");
            require(_operand != 0x0, "Can't add null contract");
        }
        else if (_operation == 2) // remove chain
        {
            require(_operand_chain_id != voting_chain_id_, "Cannot remove this chain... it's the voting chain. Change voting chain first!");
            require(uniwarp_contracts_[_operand_chain_id] != 0x0, "Cannot remove chain, doesn't exist!");
            require(_operand == uniwarp_contracts_[_operand_chain_id], "Operand must be the contract address");
        }
        else if (_operation == 3)    /* change pigeon */
        {
            require(uniwarp_contracts_[_operand_chain_id] != 0x0, "Cannot change pigeon address on chain that's not added!");
            require(_operand != 0x0, "Cannot set pigeon to 0x0");
            if (_operand_chain_id == chain_id_)
                require(PigeonInterface(address(uint160(_operand))).chainId() == chain_id_, "Invalid pigeon interface!");
        }
        else if (_operation == 4)    /* new voting contract (chain) */
        {
            require(_operand_chain_id != voting_chain_id_, "This is already the voting contract... you can only switch voting to a different chain");
            require(_operand == uniwarp_contracts_[_operand_chain_id], "You can only propose another uniwarp contract as the new voting contract");
            require(_operand != 0x0, "Please specify the uniwarp contract on the other end.");
        }
        else if (_operation == 5)    /* new voting expiry */
        {
            //require(_operand_chain_id == chain_id_, "Can only propose a voting expiry for this chain, the voting chain.");
            require(chain_ids_[_operand_chain_id] != 0x0, "Chain must exist to change voting time.");
            require(_operand <= 120960, "Cannot propose a voting expiry > 120960");
        }
        else if (_operation == 6)    /* new tokens_per_vote lockup */
        {
            require(_operand_chain_id == voting_chain_id_, "Can only propose a new tokens_per_vote for the voting chain.");
            require(_operand > 10**19, "tokens_per_vote must be at least 10**19");
        }
        else if (_operation == 7)    /* new tokens_per_proposal lockup */
        {
            require(_operand_chain_id == voting_chain_id_, "Can only propose a new tokens_per_proposal for the voting chain.");
            require(_operand > 10**20, "tokens_per_proposal must be at least 10**20");
        }
        else if (_operation == 8)    /* new pigeon oracle */
        {
            require(_operand_chain_id == 0x0, "Cannot specify a chain for the pigeon oracle, must be the same on all chains. Please use 0x0 for chain_id here.");
            require(_operand != 0x0, "Cannot specify a null oracle key.");
        }
        else if (_operation == 10) // disable chain
        {
            require(_operand_chain_id != voting_chain_id_, "You cannot disable the voting chain!");
            require(chain_ids_[_operand_chain_id] != 0x0, "Must specify an already added chain to disable");
            require(!disabled_chains_[_operand_chain_id], "Chain was already disabled!");
            require(_operand == uniwarp_contracts_[_operand_chain_id], "Operand must be the contract address");
        }
        else if (_operation == 11) // enable chain
        {
            require(chain_ids_[_operand_chain_id] != 0x0, "Must specify an already added chain to enable");
            require(disabled_chains_[_operand_chain_id], "Chain was already enabled!");
            require(_operand == uniwarp_contracts_[_operand_chain_id], "Operand must be the contract address");
        }
        
        return true;
    }
    
  
    function destroyProposal(uint256 _proposal_id) private
    {
        Proposal memory proposal = proposals_[_proposal_id];
        
        require(proposal.operation > 0, "Proposal does not exist");
        // return tokens to user
        
        address proposer = proposal.proposer;
        
        require(proposer != OFF_CHAIN && proposer != address(0x0), "Internal error (1)");
        
        uint256 old_balance = balances_[proposer];
        balances_[proposer] += proposal.lockedTokens;
        require(old_balance < balances_[proposer], "Internal error (2)");
        
        // remove the proposal
        delete proposals_[_proposal_id];
    }
    
    function redeemVoteTokens(uint256 _proposal_id) checkDeleted checkDisabled override external returns(bool success)
    {
        // the below line prevents people closing their vote lock early
        require(proposals_[_proposal_id].operation == 0, "Proposal must have expired or cancelled before vote can be redeemed");
        
        require(votes_[_proposal_id][msg.sender] > 0, "Vote does not exist or already redeemed");
        
        uint256 old_balance = balances_[msg.sender];
        balances_[msg.sender] += votes_[_proposal_id][msg.sender];
        require(old_balance < balances_[msg.sender], "Internal error");
        
        delete votes_[_proposal_id][msg.sender];
        return true;
    }

    
    function actionProposal(uint256 _proposal_id)  checkDeleted checkDisabled override external payable returns (bool success)
    {
        
        Proposal memory proposal = proposals_[_proposal_id];
        
        require(block.number >= proposal.expiry_block,
            "Either invalid proposal_id or expiry block hasn't occured yet.");
            
        require(proposal.operation > 0 && proposal.operation < 12,
            "Invalid proposal");
            
        require(proposal.yay > proposal.nay * 2,
            "Proposal can't be actioned because it did not pass the vote. Use cancel();");
            
        actionProposalInternal(proposal.operation, proposal.chain_id, proposal.operand, true);
        destroyProposal(_proposal_id);
        
        return true;
    }
    
    function actionProposalInternal(uint256 operation, uint256 operand_chain_id, uint256 operand, bool _broadcast) private
    {

        validateProposal(operation, operand_chain_id, operand);
        
        ProposalActioned(operation, operand_chain_id, operand);
        
        bool is_voting_chain = (chain_id_ == voting_chain_id_);
        
        if (is_voting_chain && _broadcast)
        {
            pigeonAction();
        }
         
        // 1 == add chain, 2 == remove chain, 3 == change pigeon, 4 = propose new voting contract,
        // 5 = propose new proposal block expiry, 6 = tokens_per_vote, 7 = tokens_per_proposal, 8 = change pigeon oracle key
        // 9 = change contract id on a chain, 10 = disable chain, 11 = enable chain

        if (operation == 1) // add chain
        {
            uniwarp_contracts_[operand_chain_id] = operand;
            chain_ids_[chain_count_++] = operand_chain_id;
        }
        else if (operation == 2) // del chain
        {
            delete uniwarp_contracts_[operand_chain_id];
            for (uint i = 0; i < chain_count_; ++i)
                if (chain_ids_[i] == operand_chain_id)
                    chain_ids_[i] = 0x0;
            if (operand_chain_id == chain_id_)
                deleted_ = true;
                
        }
        else if (operation == 3) // change pigeon (sending contract) on a specific chain to a specific address
        {
            if (operand_chain_id == chain_id_)
                pigeon_address_ = address(uint160(operand));
        }
        else if (operation == 4) // propose new voting chain
        {
            voting_chain_id_ = operand_chain_id;
        }
        else if (operation == 5) // propose new voting block expiry
        {
            // a proposal can change any chain's voting time even if its not the voting chain
            // this is so this figure is adjustable ahead of moving the voting chain
            if (operand_chain_id == chain_id_)
                voting_block_expiry_ = operand;
        }
        else if (operation == 6) // propose new tokens_per_vote
        {
            tokens_per_vote_ = operand;
        }
        else if (operation == 7)
        {
            tokens_per_proposal_ = operand;
        }
        else if (operation == 8)
        {
            changeOracleKeyInternal(address(uint160(operand)));
        }
        else if (operation == 9) // change contract on chain
        {
            uniwarp_contracts_[operand_chain_id] = operand;
            if (operand_chain_id == chain_id_)
                deleted_ = true;
        }
        else if (operation == 10)   // disable chain
        {
            disabled_chains_[operand_chain_id] = true;
        }
        else if (operation == 11)  // enable chain
        {
            disabled_chains_[operand_chain_id] = false;
        }
    }
    
    // anyone can clear a proposal if 1.25 * voting_block_expiry_ has passed
    function cancelProposal(uint256 _proposal_id) checkDeleted checkDisabled override external returns (bool success)
    {
        require(proposals_[_proposal_id].operation > 0, "Proposal does not exist");
        require(proposals_[_proposal_id].cancel_block < block.number,
            "Either invalid proposal_id or cancel block hasn't occured yet.");
    
        destroyProposal(_proposal_id);
        return true;
    }
    
    function twentyFivePercentMore(uint256 _number) pure private returns (uint256)
    {
        uint256 o = _number;
        uint256 n = _number + (_number / 4);
        require(n > o, "Invariant tripped");
        return n;
    }
    
    function propose(uint256 _operation, uint256 _operand_chain_id, uint256 _operand, bytes32 _explain1, bytes32 _explain2) checkDeleted checkDisabled override external returns (uint256) 
    {
        require(chain_id_ == voting_chain_id_, "You can only propose on the voting chain");
        require(balances_[msg.sender] >= tokens_per_proposal_, "Not enough UWR to propose");

        validateProposal(_operation, _operand_chain_id, _operand);

        // subtract the tokens from the user's balance until the proposal ends
        uint256 old_balance = balances_[msg.sender];
        balances_[msg.sender] -= tokens_per_proposal_;
        require(old_balance > balances_[msg.sender], "Internal error");
        
        
        uint256 id = proposal_count_++; // allocate a new proposal
        proposals_[id].proposer     = msg.sender;
        proposals_[id].operation    = _operation;
        proposals_[id].chain_id     = _operand_chain_id;
        proposals_[id].operand      = _operand;
        proposals_[id].explain1     = _explain1;
        proposals_[id].explain2     = _explain2;
        proposals_[id].lockedTokens = tokens_per_proposal_;
        
        proposals_[id].expiry_block = block.number + voting_block_expiry_;
        proposals_[id].cancel_block = block.number + twentyFivePercentMore(voting_block_expiry_);
        
        if (proposals_[id].expiry_block == block.number || block.number > proposals_[id].expiry_block)
            proposals_[id].expiry_block = block.number + 100; // this is a fallback ~8 minutes on binance smart chain, only active if voting_block_expiry_ was never set or if it was really really big

        return id;
    }
    
    function vote(uint256 _proposal_id, uint16 _yay, uint16 _nay) external checkDeleted checkDisabled override returns (bool success)
    {
        require(chain_id_ == voting_chain_id_, "You can only vote on the voting chain");
        require( !( _yay > 0 && _nay > 0 ), "You must either vote yay or nay... not both");
        require(balances_[msg.sender] >= tokens_per_vote_ * _yay && 
                balances_[msg.sender] >= tokens_per_vote_ * _nay, "Not enough UWR to vote");
                
        require(proposals_[_proposal_id].operation > 0, "You are attempting to vote on a non existent proposal id");

        require(block.number < proposals_[_proposal_id].expiry_block, "Proposal has already expired, either action() or cancel() it.");

        uint256 old_balance = balances_[msg.sender];
        uint256 charge = tokens_per_vote_ * (_yay + _nay);
        balances_[msg.sender] -= charge;
        votes_[_proposal_id][msg.sender] += charge;
        require(old_balance > balances_[msg.sender], "Internal error");

        uint16 old_yay = proposals_[_proposal_id].yay;
        uint16 old_nay = proposals_[_proposal_id].nay;
        proposals_[_proposal_id].yay += _yay;
        proposals_[_proposal_id].nay += _nay;
        require(old_yay <= proposals_[_proposal_id].yay && old_nay <= proposals_[_proposal_id].nay, "Internal error");
        
        return true;
    }
    

    function actionProposalCost() view external checkDeleted checkDisabled override returns (uint256 amount)
    {
        require(chain_id_ == voting_chain_id_, "only on the voting chain");
        uint256 cost = 0;
        for (uint i = 0; i < chain_count_; ++i)
        {
            if (chain_ids_[i] == chain_id_ ||
                chain_ids_[i] == 0x0 ||
                uniwarp_contracts_[chain_ids_[i]] == 0x0)
                continue;
            
            PigeonInterface p = PigeonInterface(pigeon_address_);    
            cost += p.pigeonCost(chain_ids_[i]);
        }
        return cost;
    }


    function pigeonAction() internal
    {
        for (uint i = 0; i < chain_count_; ++i)
        {
            if (chain_ids_[i] == chain_id_ ||
                chain_ids_[i] == 0x0 ||
                uniwarp_contracts_[chain_ids_[i]] == 0x0)
                continue;
            
            PigeonInterface p = PigeonInterface(pigeon_address_);    
            p.pigeonSend{
                value: p.pigeonCost(chain_ids_[i])
            }(0x0, PROPOSAL_ACTION_EVENT_ID, chain_ids_[i], uniwarp_contracts_[chain_ids_[i]]);
        }
    }

    function vaultFee(uint256 _dest_chain_id) view checkDeleted checkDisabled override external returns (uint256)
    {
        require(uniwarp_contracts_[_dest_chain_id] != 0x0, "Chain not supported");
        return PigeonInterface(pigeon_address_).pigeonCost(_dest_chain_id);
    }

    // place tokens into a warp vault
    // the vault will only be openable on the destination chain
    // vaults can still be sent from a disabled contract, but not to a disabled contract 
    
    function vaultInternal(address _from, uint256 _dest_chain_id, uint256 _amount) internal returns (bool success)
    {
        // todo: minimum vault amount?
        require(balances_[_from] > 0, "You have no tokens!");
        require(uniwarp_contracts_[_dest_chain_id] != 0x0, "Destination chain not currently supported.");
        require(PigeonInterface(pigeon_address_).pigeonCost(_dest_chain_id) <= msg.value, "Insufficent vaulting fee. Please check vaultFee(network_id)");
        require(!disabled_chains_[_dest_chain_id], "The chain you are vaulting to is currently disabled.");
        
        // there should be a require(balances_[_fram] >= _amount) here, but it was forgotten,
        // fortunately solidity 0.8.x auto reverts if balance is insufficient here 

        balances_[_from] -= _amount;
        balances_[OFF_CHAIN] += _amount;
        
        emit Vaulted(uint256(uint160(_from)), _dest_chain_id, _amount);

        PigeonInterface p = PigeonInterface(pigeon_address_);    
        p.pigeonSend{
                value: p.pigeonCost(_dest_chain_id)
        }(0x0, VAULTED_EVENT_ID, _dest_chain_id, uniwarp_contracts_[_dest_chain_id]);        
        emit Transfer(_from, OFF_CHAIN, _amount);
        return true;
    }

    function vault(uint256 _dest_chain_id, uint256 _amount) checkDeleted external payable override returns (bool success)
    {
        return vaultInternal(msg.sender, _dest_chain_id, _amount);
    }


    function vaultFrom(address _from, uint256 _dest_chain_id, uint256 _amount) checkDeleted external payable override returns (bool success)
    {
        uint256 current_allowance = allowed_[_from][msg.sender];
        require(balances_[_from] >= _amount && current_allowance >= _amount);
        if (current_allowance < MAX_UINT256)
            allowed_[_from][msg.sender] -= _amount;
            
        vaultInternal(_from, _dest_chain_id, _amount);
        
        return true;
    }


    function name() external view returns ( string memory )
    {
        if (deleted_)
            return "Uniwarp [Deleted]";
        return "Uniwarp";
    }
    
    function symbol() external view returns ( string memory )
    {
        if (deleted_)
            return "UWRDELETED";
        return "UWR";
    }
    
    function decimals() external pure returns ( uint8 )
    {
        return 18;
    }
    
    function total_supply() external view override returns ( uint256 )
    {
        if (deleted_)
            return 0;
            
        return total_supply_; 
    }
    
    function chain_id() external view returns ( uint256 )
    {
        return chain_id_;
    }
    
    
    address setup_oracle_;
    
    function setupComplete() checkDisabled checkDeleted external returns (bool succcess)
    {
        setup_oracle_ = address(0x0);        
        return true;
    }
    
    function setupProposal(uint256 operation, uint256 operand_chain_id, uint256 operand) checkDisabled checkDeleted external returns (bool success)
    {
        
        require(setup_oracle_ != address (0x0) && msg.sender == setup_oracle_, "The contract must be in setup mode and you must be the deployer.");
        actionProposalInternal(operation, operand_chain_id, operand, false);
        return true;
    }
    
    function setupChains(uint256[] memory _chain_ids, uint256[] memory _uniwarp_contracts, bool setupDone) checkDisabled checkDeleted external returns (bool success)
    {
        require(setup_oracle_ != address (0x0) && msg.sender == setup_oracle_, "The contract must be in setup mode and you must be the deployer.");
        if (setupDone)
            setup_oracle_ = address(0x0);

        return updateChains(_chain_ids, _uniwarp_contracts);   
    }
    
    function updateChains(uint256[] memory _chain_ids, uint256[] memory _uniwarp_contracts) private returns (bool success)
    {
        bool voting_chain_found_in_chain_ids = false;
        chain_count_ = _chain_ids.length;
        for (uint i = 0; i < _chain_ids.length; ++i)
        {
            chain_ids_[i] = _chain_ids[i];
            if (_chain_ids[i] == voting_chain_id_)
                voting_chain_found_in_chain_ids = true;
                    
            if (_chain_ids[i] == chain_id_)
                uniwarp_contracts_[chain_id_] = uint256(uint160(address(this)));
            else
                uniwarp_contracts_[_chain_ids[i]] = _uniwarp_contracts[i];
        }
        require(voting_chain_found_in_chain_ids, "You must specify the voting chain in the chain ids");
        return true;
    }
    
    constructor (
        bool _is_first_chain,
        uint256 _chain_id, 

        address _pigeon_address,
        address _pigeon_oracle,

        uint256 _voting_chain_id,     // votes are proxied to the uniwarp contract on the nominated chain and contract
        
        uint256 _voting_block_expiry,
        
        uint256[] memory _chain_ids, uint256[] memory _uniwarp_contracts
        )
        PigeonReceive (_pigeon_oracle) 
    {
        setup_oracle_ = msg.sender;
        total_supply_ = 100*(10**24); // 100 million warpies hard coded
        chain_id_ = _chain_id;
        pigeon_address_ = _pigeon_address;
        voting_block_expiry_ = _voting_block_expiry;
        voting_chain_id_ = _voting_chain_id;
        
        require(PigeonInterface(_pigeon_address).getPigeonOracleKey() == _pigeon_oracle, "Pigeon reported different oracle than provided");

        if (_is_first_chain)
        {
            uint256 share = total_supply_/5.0;
            /*
            // these are test addresses for test rig
            balances_[0x61b1D420b2852067eE1A4F79511fAb70b7F4F78c] += share;
            balances_[0x61b1D420b2852067eE1A4F79511fAb70b7F4F78c] += share;
            balances_[0x61b1D420b2852067eE1A4F79511fAb70b7F4F78c] += share;
            balances_[0x5B199ee407a183bfA1cBAD4Cfac6b90470a104a9] += share;
            balances_[0x5B199ee407a183bfA1cBAD4Cfac6b90470a104a9] += share;
            */
            balances_[0x241e6c88a09E9Bcfdd4C9cE718ac41757ae0Eaf6] += share; // s
            balances_[0xdB72Dbcf738dDc8F691D39DE2FAa950a0378eeE3] += share; // w
            balances_[0xA5497fb28af83B0C0172bD5A4FDc61c365D9eE3E] += share; // t
            balances_[0xE9fFFE7c9b322c7065947A8232DDF1B8ff1C82f8] += share; // a
            balances_[0x34070F4a89B0b8e51402Fb3C81413bcC192C7cC3] += share; // r
            
        }
        else
            balances_[OFF_CHAIN] = total_supply_;

        updateChains(_chain_ids, _uniwarp_contracts);
    }
    
    
    function getPigeonOracleKey() view external returns (address)
    {
        return getOracleKey();
    }


    function transfer(address _to, uint256 _value) external override returns (bool success)
    {
        require(balances_[msg.sender] >= _value);
        balances_[msg.sender] -= _value;
        balances_[_to] += _value;
        emit Transfer(msg.sender, _to, _value);
        return true;
    }

    function transferFrom(address _from, address _to, uint256 _value) external override returns (bool success)
    {
        uint256 current_allowance = allowed_[_from][msg.sender];
        require(balances_[_from] >= _value && current_allowance >= _value, "Insufficent allowance");
        balances_[_to] += _value;
        balances_[_from] -= _value;
        if (current_allowance < MAX_UINT256) {
            allowed_[_from][msg.sender] -= _value;
        }
        emit Transfer(_from, _to, _value);
        return true;
    }

    function balanceOf(address _owner) external override view returns (uint256 balance)
    {
        return balances_[_owner];
    }

    function approve(address _spender, uint256 _value) external override returns (bool success)
    {
        allowed_[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value); //solhint-disable-line indent, no-unused-vars
        return true;
    }

    function allowance(address _owner, address _spender) external override view returns (uint256 remaining)
    {
        return allowed_[_owner][_spender];
    }
}