// SPDX-License-Identifier: AGPL-1.0
pragma solidity ^0.8.0;

import './Counters.sol';
import './SafeMath.sol';
import './IERC20.sol';
import './IRocketStake.sol';
import './IRocketStorage.sol';
import './IMigrationCompatible.sol';
import './IRocketDepositPool.sol';
import './IRocketTokenRETH.sol';

contract RETHBuyer {
    using SafeMath for uint256;
    
    address rocket_storage_address;
    address owner;

    constructor(address _rocket_storage_address) {
        rocket_storage_address = _rocket_storage_address;
        owner = msg.sender;
    }

    receive() external payable {}

    modifier onlyOwner {
        require(msg.sender == owner, "Only RocketStake can do that");
        _;
    }

    function burn(uint256 reth_amount) external onlyOwner returns(uint256 _eth_received) {
        require(reth_amount > 0, "You must burn a non zero positive amount of reth");

        // setup RP
        IRocketStorage rocket_storage = IRocketStorage(rocket_storage_address);
        IRocketTokenRETH rocket_token_reth = IRocketTokenRETH(rocket_storage.getAddress(keccak256(abi.encodePacked("contract.address", "rocketTokenRETH"))));

        // burn the reth specified and record this contract's balance change
        uint256 starting_balance = address(this).balance;
        rocket_token_reth.burn(reth_amount);
        uint256 eth_received = address(this).balance.sub(starting_balance);

        // send the owner of this contract the eth received from rocket pool and return
        payable(owner).transfer(eth_received);
        return eth_received;
    } 

    function deposit() payable external onlyOwner returns(uint256 _reth_added_to_stake) {
        require(msg.value > 0, "Must deposit a non-zero amount of ETH");

        // setup RP
        IRocketStorage rocket_storage = IRocketStorage(rocket_storage_address);
        IRocketDepositPool rocket_deposit_pool = IRocketDepositPool(rocket_storage.getAddress(keccak256(abi.encodePacked("contract.address", "rocketDepositPool"))));
        IRocketTokenRETH rocket_token_reth = IRocketTokenRETH(rocket_storage.getAddress(keccak256(abi.encodePacked("contract.address", "rocketTokenRETH"))));

        // deposit msg.value into rocket pool and record the change in our rETH balance as a result
        uint256 reth_supply_before = rocket_token_reth.balanceOf(address(this));
        rocket_deposit_pool.deposit{ value: msg.value }();
        uint256 reth_supply_after = rocket_token_reth.balanceOf(address(this));

        // return the change in total rETH held by this contract
        return reth_supply_after.sub(reth_supply_before);
    }

    function lastDepositBlock() external view returns(uint256 _last_deposit_block) {
        IRocketStorage rocket_storage = IRocketStorage(rocket_storage_address);
        return rocket_storage.getUint(keccak256(abi.encodePacked("user.deposit.block", address(this))));
    }
}

contract RocketStake is IRocketStake {
    using SafeMath for uint256;

    struct Staker {
        RETHBuyer reth_buyer;
        uint256 staked_reth;
        bool exists;
    }

    uint256 total_reth_held;
    mapping(address => Staker) internal stakers;
    address rocket_storage_address;

    constructor(address _rocket_storage_address) {
        rocket_storage_address = _rocket_storage_address;
    }

    receive() external payable {}

    modifier safeWithdrawal(uint256 eth_amount, address staker) {
        require(eth_amount > 0, "You must withdraw more than 0 ETH");
        require(stakers[staker].exists == true, "Staker not registered yet.");
        require(stakers[staker].staked_reth > 0, "Nothing staked here.");

        // ensures that the staker has waited long enough to withdraw from rocket pool
        // rocket pool has a cooldown period after minting rETH 
        IRocketStorage rocket_storage = IRocketStorage(rocket_storage_address);
        require(
            block.timestamp.sub(stakers[staker].reth_buyer.lastDepositBlock())
                > rocket_storage.getUint(keccak256(abi.encodePacked(keccak256("dao.protocol.setting.network"), "network.reth.deposit.delay"))), 
            "Rocket Pool will not let you move or withdraw your rETH yet."
        );
        _;
    } 

    function register() external override {
        if (stakers[msg.sender].exists != true) {
            stakers[msg.sender].exists = true;
            stakers[msg.sender].reth_buyer = new RETHBuyer(rocket_storage_address);

            emit Register(msg.sender);
        }
    }

    function stake() external payable override {
        require(msg.value > 0, "You must send a non-zero amount of eth to stake.");
        
        // register and create reth_buyer if doesn't exist already
        if (stakers[msg.sender].exists != true) {
            stakers[msg.sender].exists = true;
            stakers[msg.sender].reth_buyer = new RETHBuyer(rocket_storage_address);

            emit Register(msg.sender);
        }

        // have the reth_buyer deposit eth for rETH and hold on to it
        // this value will never equal zero because Rocket Pool reverts when depositing an amount below their set minimum
        // note: ui should prevent reverting due to lower than minimum deposit error
        uint256 reth_added_to_stake = stakers[msg.sender].reth_buyer.deposit{ value: msg.value }();

        // update balances
        total_reth_held = total_reth_held.add(reth_added_to_stake);
        stakers[msg.sender].staked_reth = stakers[msg.sender].staked_reth.add(reth_added_to_stake);

        emit Stake(msg.sender, reth_added_to_stake, msg.value, stakers[msg.sender].staked_reth);
    }

    function withdraw(uint256 eth_amount) external override safeWithdrawal(eth_amount, msg.sender) {
        uint256 eth_received = _burnAndReturnETH(eth_amount, msg.sender);

        // send the received eth to the staker
        payable(msg.sender).transfer(eth_received);

        emit Withdraw(msg.sender, eth_received, stakers[msg.sender].staked_reth);
    }

    function migrate(
        address next_contract_address,
        uint256 eth_amount
    ) override external safeWithdrawal(eth_amount, msg.sender) {
        uint256 eth_received = _burnAndReturnETH(eth_amount, msg.sender);

        // send the user's funds to a contract of their choosing
        IMigrationCompatible(next_contract_address).startTransfer(eth_received, msg.sender);
        payable(next_contract_address).transfer(eth_received);
        IMigrationCompatible(next_contract_address).closeTransfer(eth_received, msg.sender);

        emit Migrate(msg.sender, next_contract_address, eth_received);
    }

    function depositDelay(address staker) override external view returns(
        uint256 _last_deposit_block,
        uint256 _block_number,
        uint256 _deposit_delay
    ) {
        IRocketStorage rocket_storage = IRocketStorage(rocket_storage_address);
        uint256 deposit_delay = rocket_storage.getUint(keccak256(abi.encodePacked(keccak256("dao.protocol.setting.network"), "network.reth.deposit.delay")));
        return(
            stakers[staker].exists == true 
                ? stakers[staker].reth_buyer.lastDepositBlock()
                : 0,
            block.number,
            deposit_delay
        );
    }
    
    function stakedETH(address staker) override external view returns(uint256 staked_eth) {
        IRocketStorage rocket_storage = IRocketStorage(rocket_storage_address);
        IRocketTokenRETH rocket_token_reth = IRocketTokenRETH(rocket_storage.getAddress(keccak256(abi.encodePacked("contract.address", "rocketTokenRETH"))));
        return rocket_token_reth.getEthValue(stakers[staker].staked_reth);
    }

    function stakedRETH(address staker) override external view returns(uint256 staked_reth) {
        return stakers[staker].staked_reth;
    }

    function registered(address staker) override external view returns(bool exists) {
        return stakers[staker].exists;
    }

    function buyerAddress(address staker) override external view returns(address) {
        return stakers[staker].exists == true ? address(stakers[staker].reth_buyer) : address(0);
    }

    function rocketPoolRETHCollateral() external override view returns(uint256 collateral) {
        IRocketStorage rocket_storage = IRocketStorage(rocket_storage_address);
        IRocketTokenRETH rocket_token_reth = IRocketTokenRETH(rocket_storage.getAddress(keccak256(abi.encodePacked("contract.address", "rocketTokenRETH"))));
        return rocket_token_reth.getTotalCollateral();
    }

    function totalRETHHeld() external override view returns(uint256 collateral) {
        return total_reth_held;
    }

    function totalETHHeld() external override view returns(uint256 collateral) {
        IRocketStorage rocket_storage = IRocketStorage(rocket_storage_address);
        IRocketTokenRETH rocket_token_reth = IRocketTokenRETH(rocket_storage.getAddress(keccak256(abi.encodePacked("contract.address", "rocketTokenRETH"))));
        return rocket_token_reth.getEthValue(total_reth_held);
    }

    function _burnAndReturnETH(uint256 eth_amount, address staker) internal returns(uint256 _eth_received) {
        // setup RP contracts
        IRocketStorage rocket_storage = IRocketStorage(rocket_storage_address);
        IRocketTokenRETH rocket_token_reth = IRocketTokenRETH(rocket_storage.getAddress(keccak256(abi.encodePacked("contract.address", "rocketTokenRETH"))));
        
        // make sure the staker is not trying to withdraw more ETH than their staked rETH is worth
        uint256 eth_able_to_be_withdrawn = rocket_token_reth.getEthValue(stakers[staker].staked_reth);
        require(eth_amount <= eth_able_to_be_withdrawn, "You cannot withdraw more ETH than you have staked.");

        // determine how much rETH the supplied eth_amount translates to
        uint256 reth_to_burn = rocket_token_reth.getRethValue(eth_amount);

        // tell the buyer contract to burn some of its rETH and send the resulting ETH proceeds back to this contract
        uint256 eth_received = stakers[staker].reth_buyer.burn(reth_to_burn);

        // add a check in the odd case where no ETH is return by the reth_buyers burn function
        require(eth_received > 0, "No ETH was received from the rETH burn");

        // update balances
        total_reth_held = total_reth_held.sub(reth_to_burn);
        stakers[staker].staked_reth = stakers[staker].staked_reth.sub(reth_to_burn);

        return eth_received;
    }
}