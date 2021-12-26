pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./Pausable.sol";
import "./ERC20.sol";
import "./LFLC.sol";


interface InterfaceLFLC {
    function balanceOf(address owner) external view returns (uint256 balance);
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256 tokenId);
}

contract Ribbit is ERC20, Ownable, Pausable {

    InterfaceLFLC public LFLC;

    // a mapping for an address for whether or not it can mint
    mapping(address => bool) controllers;

    // The starting block.
    uint256 public startBlock;

    // The interval that the user is paid out.
    uint256 public interval     = 86400;
    uint256 public rate         = 1000 ether;

    //Max rewards from LFLC staking
    uint256 public constant cap = 200000000 ether;

    // The rewards for the user.
    mapping(address => uint256) public rewards;

    // The last time they were paid out.
    mapping(address => uint256) public lastUpdate;

    // Only allow the contract to interact with it.
    modifier onlyFromLFLC() {
        require(msg.sender == address(LFLC));
        _;
    }

    constructor(address lflcAddress) ERC20("Ribbit Token", "Ribbit") {

        // Set the LFLC erc 721 address.
        LFLC = InterfaceLFLC(lflcAddress);

        // Set the starting block.
        startBlock = block.timestamp;

        // Pause the system so no one can interact with it.
        _pause();
    }

    /*
        Admin Utility.
    */

    // Pause it.
    function pause() public onlyOwner { _pause(); }

    // Unpause it.
    function unpause() public onlyOwner { _unpause(); }

    // Set the start block.
    function setStartBlock(uint256 arg) public onlyOwner {
        if(arg == 0){
            startBlock = block.timestamp;
        }else{
            startBlock = arg;
        }
    }

    // Set the start block.
    function setIntervalAndRate(uint256 _interval, uint256 _rate) public onlyOwner {
        interval = _interval;
        rate = _rate;
    }


    // Set the address for the LFLC contract.
    function setLFLCContractAddress(address _lflc) public onlyOwner {
        LFLC = InterfaceLFLC(_lflc);
    }

    // Phase 2 Minting
    function mintSecondPhase(address user, uint256 amount) public onlyOwner {
        require(controllers[msg.sender], "Only controllers can mint");
        _mint(user, amount);
    }

    /**
    * enables an address to mint / burn
    * @param controller the address to enable
    */
    function addController(address controller) external onlyOwner {
        controllers[controller] = true;
    }

    /**
    * disables an address from minting / burning
    * @param controller the address to disbale
    */
    function removeController(address controller) external onlyOwner {
        controllers[controller] = false;
    }

    /*
        User Utilities.
    */

    // Transfer the tokens (only accessable from the contract).
    function transferTokens(address _from, address _to) onlyFromLFLC whenNotPaused external {

        // Refactor this.
        if(_from != address(0)){
            rewards[_from]    += getPendingReward(_from);
            lastUpdate[_from]  = block.timestamp;
        }

        if(_to != address(0)){
            rewards[_to]    += getPendingReward(_to);
            lastUpdate[_to]  = block.timestamp;
        }
    }

    // Pay out the holder.
    function claimReward() external whenNotPaused {
        //Ribbit earned through LFLC staking will not be claimable after 200M LFLC cap has been minted.
        require(_totalSupply < cap, "Sorry ser, LFLC staking has ended.");

        // Mint the user their tokens.
        _mint(msg.sender, rewards[msg.sender] + getPendingReward(msg.sender));

        // Reset the rewards for the user.
        rewards[msg.sender] = 0;
        lastUpdate[msg.sender] = block.timestamp;
    }

    // The rewards to the user.
    function getTotalClaimable(address user) external view returns(uint256) {
        return rewards[user] + getPendingReward(user);
    }

    // The rewards to the user.
    function getlastUpdate(address user) external view returns(uint256) {
        return lastUpdate[user];
    }

    // gets the Ribbit you own and returns it for our staking dapp
    function getRibbit(address user) external view returns (uint256) {
        uint256 balance = balanceOf(user);
        return balance;
    }

    // gets the LFLC NFTs you own and returns it for our staking dapp
    function getLFLC(address user) external view returns (uint256) {
        uint256 balance = LFLC.balanceOf(user);
        return balance;
    }

    // gets the LFLC token ids you own and returns it for our staking dapp
    function getLFLCTokenIds(address _owner) public view returns (uint256[] memory _tokensOfOwner) {
        _tokensOfOwner = new uint256[](LFLC.balanceOf(_owner));
        for (uint256 i;i<LFLC.balanceOf(_owner);i++){
            _tokensOfOwner[i] = LFLC.tokenOfOwnerByIndex(_owner, i);
        }
    }

    // Get the total rewards.
    function getPendingReward(address user) internal view returns(uint256) {
        return LFLC.balanceOf(user) * 
               rate *
               (block.timestamp - (lastUpdate[user] >= startBlock ? lastUpdate[user] : startBlock)) / 
               interval;
    }
}