// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 *
 *                                    (/  #%%                                    
 *                                 ((((   %%%%%*                                 
 *                                /(/(,  #%%%%%%*                                
 *                          (((((/((/(   %%%%%%%%#%%%%/                          
 *                       ((((((((((((/  *%%%%%%%%%%%%%%%%#                       
 *                      /((((((((((((*  #%%%%%%%%%%%%%%%%%%%                     
 *                        ./(((((((((,  #%%%%%%%%%%%%%%%%%%%%%                   
 *                 *(((((((((((((((((   %%%%%%%%%%%%%%%%%%%%%%%                  
 *                ,((((((((((((((((((   %%%%%%%%%%%%%%%%%%%%%%%%                 
 *                (((((((((((((((((((   %%%%%%%%%%%%%%%%%%%%%%%%%                
 *               .(/(((((((((((((((((   %%%%%%%%%%%%%%%%%%%%%%%%#.               
 *                    (((((((((((((((   %%%%%%%%%%%%%%%%%%%%%%%%%                
 *                   /(((((((((((((((   %%%%%%%%%%%%%%%%%%%%%##*                 
 *               *(((((((((((((((((((   %%%%%#%%#%%%%%%%%%%#%%                   
 *                (((((((((((((((((((.  %%%%%          %%%%%%                    
 *                (((((((((((((((((((,  #%%%         .%%%%%%,                    
 *                 ((((((((((((((((((/  (%%%       %%%%%%%%%.                    
 *                           ((((((((/  ,%%%   .%%%%%%%%%%%%%                    
 *                        *((((((((((/   %%#   %%%%%%%%%%%%%%                    
 *                    //((((((((((((((        ,%%%%%%%%%%%%%.                    
 *                      ((((((((((((((        %%%%%%%%%%%%(                      
 *                        (//(((((((((       *%%%%%%%%%#%                        
 *                          /(((((((((,      %%%%%%#%%(                          
 *                             (((((((*     *%%%%%%%                             
 *                               ./((((     %%%%#  
 * 
 * Hello Guardians,
 * We don't have a lot of time. You have been called upon to act, the time is now or never.
 * Together we can collectively push back the damage that has been done to the amazon.
 * 
 * This contract emits tickets that entitle you to NFTs  which you can use to join the fight.
 * Gas saving measures have been used to even further reduce carbon emission.
 * ~ See you in the rainforest.
 *
 * Project By: @nemus_earth
 * Developed By: @notmokk
 * 
 */

import "./AccessControl.sol";
import "./ERC1155.sol";
import "./MerkleProof.sol";
import "./Strings.sol";
import "./SafeMath.sol";
import "./Counters.sol";
import './AbstractMintVoucherFactory.sol';

contract NeaMintTicketFactory is AbstractMintVoucherFactory  {
    using SafeMath for uint256;
    using Counters for Counters.Counter;

    Counters.Counter private mtCounter; 
    
    uint256 private constant MAX_PER_EARLY_ACCESS_ADDRESS = 5;

    address payable public treasuryWallet;
    address payable public nemusWallet;
    uint256 public treasuryPercentage;
    uint256 public nemusPercentage;

    mapping(address => bool) public isOnEarlyAccessList;
    mapping(address => uint256) public earlyAccessMintedCounts;
    mapping(uint256 => MintTicket) public mintTickets;
    
    event Claimed(uint index, address indexed account, uint amount);
    event ClaimedMultiple(uint[] index, address indexed account, uint[] amount);

    struct MintTicket {
        bool saleIsOpen;
        uint256 earlyAccessOpens; // Early access starting timestamp
        uint256 publicSaleOpens; // Public sale starting timestamp
        uint256 publicSaleCloses; // Public sale ending timestamp
        uint256 mintPrice; // Price of minting
        uint256 maxSupply; // Max possible supply of individual tickets
        uint256 maxPerWallet; // Max amount per users wallet
        uint256 maxMintPerTxn; // Max amount a user can mint per tx
        uint256 sizeID; // ID for ticket size reference
        string metadataHash; // ID for metadata reference
        address redeemableContract; // contract of the redeemable NFT
        mapping(address => uint256) claimedMTs;
    }
   
    constructor(
        string memory _name, 
        string memory _symbol,
        address _treasuryAddress,
        address _nemusAddress
    ) ERC1155("https://v8-nem-devapi-3lus7.ondigitalocean.app/voucher/") {
        name_ = _name;
        symbol_ = _symbol;
        treasuryWallet = payable(_treasuryAddress);
        nemusWallet = payable(_nemusAddress);
        treasuryPercentage = 50;
        nemusPercentage = 50;
    }

    function addMintTicket(
        uint256 _earlyAccessOpens,
        uint256 _publicSaleOpens, 
        uint256 _publicSaleCloses, 
        uint256 _mintPrice, 
        uint256 _maxSupply,
        uint256 _maxMintPerTxn,
        uint256 _sizeID,
        string memory _metadataHash,
        address _redeemableContract,
        uint256 _maxPerWallet
    ) external onlyOwner {
        require(_earlyAccessOpens < _publicSaleOpens, "addMintTicket: open window must be before close window");
        require(_publicSaleOpens < _publicSaleCloses, "addMintTicket: open window must be before close window");
        require(_publicSaleOpens > 0 && _publicSaleCloses > 0 && _earlyAccessOpens > 0, "addMintTicket: window cannot be 0");


        MintTicket storage mt = mintTickets[mtCounter.current()];
        mt.saleIsOpen = false;
        mt.earlyAccessOpens = _earlyAccessOpens;
        mt.publicSaleOpens = _publicSaleOpens;
        mt.publicSaleCloses = _publicSaleCloses;
        mt.mintPrice = _mintPrice;
        mt.maxSupply = _maxSupply;
        mt.maxMintPerTxn = _maxMintPerTxn;
        mt.maxPerWallet = _maxPerWallet;
        mt.sizeID = _sizeID;
        mt.metadataHash = _metadataHash;
        mt.redeemableContract = _redeemableContract;
        mtCounter.increment();

    }

    function editMintTicket(
        uint256 _earlyAccessOpens,
        uint256 _publicSaleOpens, 
        uint256 _publicSaleCloses, 
        uint256 _mintPrice, 
        uint256 _maxSupply,
        uint256 _maxMintPerTxn,
        uint256 _sizeID,
        string memory _metadataHash,        
        address _redeemableContract, 
        uint256 _mtIndex,
        bool _saleIsOpen,
        uint256 _maxPerWallet
    ) external onlyOwner {
        require(_earlyAccessOpens < _publicSaleOpens, "addMintTicket: open window must be before close window");
        require(_publicSaleOpens < _publicSaleCloses, "addMintTicket: open window must be before close window");
        require(_publicSaleOpens > 0 && _publicSaleCloses > 0 && _earlyAccessOpens > 0, "addMintTicket: window cannot be 0");

        mintTickets[_mtIndex].earlyAccessOpens = _earlyAccessOpens;
        mintTickets[_mtIndex].publicSaleOpens = _publicSaleOpens;
        mintTickets[_mtIndex].publicSaleCloses = _publicSaleCloses;
        mintTickets[_mtIndex].mintPrice = _mintPrice;  
        mintTickets[_mtIndex].maxSupply = _maxSupply;    
        mintTickets[_mtIndex].maxMintPerTxn = _maxMintPerTxn;
        mintTickets[_mtIndex].sizeID = _sizeID; 
        mintTickets[_mtIndex].metadataHash = _metadataHash;    
        mintTickets[_mtIndex].redeemableContract = _redeemableContract;
        mintTickets[_mtIndex].saleIsOpen = _saleIsOpen; 
        mintTickets[_mtIndex].maxPerWallet = _maxPerWallet; 
    }       

    function burnFromRedeem(
        address account, 
        uint256 mtIndex, 
        uint256 amount
    ) external {
        require(mintTickets[mtIndex].redeemableContract == msg.sender, "Burnable: Only allowed from redeemable contract");
        _burn(account, mtIndex, amount);
    }  

    function claim(
        uint256 amount,
        uint256 mtIndex
    ) external payable {
        // Verify claim is valid
        require(isValidClaim(amount,mtIndex));
        
        // Return excess funds to sender if they've overpaid
        uint256 excessPayment = msg.value.sub(amount.mul(mintTickets[mtIndex].mintPrice));
        if (excessPayment > 0) {
            (bool returnExcessStatus, ) = _msgSender().call{value: excessPayment}("");
            require(returnExcessStatus, "Error returning excess payment");
        }
        
        // Add claimed amount to mintTicket index to keep track of user claiming
        mintTickets[mtIndex].claimedMTs[msg.sender] = mintTickets[mtIndex].claimedMTs[msg.sender].add(amount);
        
        // Mint it
        _mint(msg.sender, mtIndex, amount, "");

        // Emit claimed event
        emit Claimed(mtIndex, msg.sender, amount);
    }

    function claimMultiple(
        uint256[] calldata amounts,
        uint256[] calldata mtIndexes
    ) external payable {

        // Verify that contract is not paused
        require(!paused(), "Claim: claiming is paused");

        //validate all tokens being claimed and aggregate a total cost due
        for (uint i=0; i< mtIndexes.length; i++) {
           require(isValidClaim(amounts[i],mtIndexes[i]), "One or more claims are invalid");
        }

        // Add claimed amount to mintTicket index to keep track of user claiming
        for (uint i=0; i< mtIndexes.length; i++) {
            mintTickets[mtIndexes[i]].claimedMTs[msg.sender] = mintTickets[mtIndexes[i]].claimedMTs[msg.sender].add(amounts[i]);
        }

        _mintBatch(msg.sender, mtIndexes, amounts, "");

        // Emit claimed event
        emit ClaimedMultiple(mtIndexes, msg.sender, amounts);

    }

    function claimEarlyAccess(uint256 _count, uint256 mtIndex) external payable {
        require(isValidEarlyAccessClaim(_count, mtIndex));

        // Return excess funds to sender if they've overpaid
        uint256 excessPayment = msg.value.sub(_count.mul(mintTickets[mtIndex].mintPrice));
        if (excessPayment > 0) {
            (bool returnExcessStatus, ) = _msgSender().call{value: excessPayment}("");
            require(returnExcessStatus, "Error returning excess payment");
        }

        // Add claimed amount to mintTicket index to keep track of user claiming
        mintTickets[mtIndex].claimedMTs[msg.sender] = mintTickets[mtIndex].claimedMTs[msg.sender].add(_count);
        uint256 userMintedAmount = earlyAccessMintedCounts[msg.sender] + _count;
        require(userMintedAmount <= MAX_PER_EARLY_ACCESS_ADDRESS, "Max early access count per address exceeded");

        // Mint it!
        _mint(msg.sender, mtIndex, _count, "");

        // Add early access count to keep track of early access claim
        earlyAccessMintedCounts[msg.sender] = userMintedAmount;

        // Emit claimed event
        emit Claimed(mtIndex, msg.sender, _count);
    }

    function claimMultipleEarlyAccess(uint256[] calldata _count, uint256[] calldata mtIndexes) external payable {
        // Verify that contract is not paused
        require(!paused(), "Claim: claiming is paused");

        //validate all tokens being claimed and aggregate a total cost due
        for (uint i=0; i< mtIndexes.length; i++) {
           require(isValidEarlyAccessClaim(_count[i], mtIndexes[i]), "One or more claims are invalid");
        }

        // Add claimed amount to mintTicket index to keep track of user claiming
        uint256 userMintedAmount;
        for (uint i=0; i< mtIndexes.length; i++) {
            mintTickets[mtIndexes[i]].claimedMTs[msg.sender] = mintTickets[mtIndexes[i]].claimedMTs[msg.sender].add(_count[i]);
            userMintedAmount = earlyAccessMintedCounts[msg.sender] + _count[i];
        }

        // Mint it!
        _mintBatch(msg.sender, mtIndexes, _count, "");

        // Emit claimed event
        emit ClaimedMultiple(mtIndexes, msg.sender, _count);

    }

    function mint(
        address to,
        uint256 numPasses,
        uint256 mtIndex) public onlyOwner
    {
        _mint(to, mtIndex, numPasses, "");
    }

    function mintBatch(
        address to,
        uint256[] calldata numPasses,
        uint256[] calldata mtIndexes) public onlyOwner
    {
        _mintBatch(to, mtIndexes, numPasses, "");
    }

    function isValidClaim(
        uint256 numPasses,
        uint256 mtIndexes) internal view returns (bool) {
         // verify contract is not paused
        require(mintTickets[mtIndexes].saleIsOpen, "Sale is paused");
        require(!paused(), "Claim: claiming is paused");
        // verify mint pass for given index exists
        require(mintTickets[mtIndexes].publicSaleOpens != 0, "Claim: Mint pass does not exist");
        // Verify within window
        require (block.timestamp > mintTickets[mtIndexes].publicSaleOpens && block.timestamp < mintTickets[mtIndexes].publicSaleCloses, "Claim: time window closed");
        // Verify minting price
        require(msg.value >= numPasses.mul(mintTickets[mtIndexes].mintPrice), "Claim: Ether value incorrect");
        // Verify numPasses is within remaining claimable amount 
        require(mintTickets[mtIndexes].claimedMTs[msg.sender].add(numPasses) <= mintTickets[mtIndexes].maxPerWallet, "Claim: Not allowed to claim that many from one wallet");
        require(numPasses <= mintTickets[mtIndexes].maxMintPerTxn, "Max quantity per transaction exceeded");

        require(totalSupply(mtIndexes) + numPasses <= mintTickets[mtIndexes].maxSupply, "Purchase would exceed max supply");
        
        return true;
         
    }

    function isValidEarlyAccessClaim(uint256 _count, uint256 mtIndex) internal view returns (bool) {
            // Verify there is an amount to be minted
            require(_count != 0, "Invalid count");
            // Verfiy sender is on early access list
            require(isOnEarlyAccessList[msg.sender], "Address not on early access list");
            // Verify within window
            require(isEarlyAccessOpen(mtIndex), "Early access window not open");
            // Verify sender value is correct for amount of passes being minted
            require(msg.value >= _count.mul(mintTickets[mtIndex].mintPrice), "Claim: Ether value incorrect");
            // Verify purchaase amount does not exceed max amount of passes
            require(totalSupply(mtIndex) + _count <= mintTickets[mtIndex].maxSupply, "Purchase would exceed max supply");

            return true;
    }

    function getClaimedMts(uint256 mtIndex, address userAdress) public view returns (uint256) {
        return mintTickets[mtIndex].claimedMTs[userAdress];
    }

    function getTicketSizeID(uint256 mtIndex) external view returns(uint256) {
        return mintTickets[mtIndex].sizeID;
    }

    function getRemainingEarlyAccessMints(address _addr) public view returns (uint256) {
        if (!isOnEarlyAccessList[_addr]) {
            return 0;
        }
        return MAX_PER_EARLY_ACCESS_ADDRESS - earlyAccessMintedCounts[_addr];
    }

    function addToEarlyAccessList(address[] memory toEarlyAccessList) external onlyOwner {
        for (uint256 i = 0; i < toEarlyAccessList.length; i++) {
            isOnEarlyAccessList[toEarlyAccessList[i]] = true;
        }
    }

    function removeFromEarlyAccessList(address[] memory toRemove) external onlyOwner {
        for (uint256 i = 0; i < toRemove.length; i++) {
            isOnEarlyAccessList[toRemove[i]] = false;
        }
    }

    function isEarlyAccessOpen(uint256 mtIndex) public view returns (bool) {
        return block.timestamp >= mintTickets[mtIndex].earlyAccessOpens;
    }

    function isSaleOpen(uint256 mtIndex) public view returns (bool) {
        return mintTickets[mtIndex].saleIsOpen;
    }

    function turnSaleOn(uint256 mtIndex) external onlyOwner{
         mintTickets[mtIndex].saleIsOpen = true;
    }

    function turnSaleOff(uint256 mtIndex) external onlyOwner{
         mintTickets[mtIndex].saleIsOpen = false;
    }

    function updatePayoutPercentage(uint256 _treasuryPercentage, uint256 _nemusPercentage) external onlyOwner 
    {
        require(_treasuryPercentage + _nemusPercentage <= 100, "Total percentage cannot be greater than 100");
        treasuryPercentage = _treasuryPercentage;
        nemusPercentage = _nemusPercentage;
    }
    
    function withdrawFunds() public onlyOwner
    {
        uint256 currentBalance = address(this).balance;
        uint256 amount1 = (currentBalance * treasuryPercentage)/100;
        uint256 amount2 = currentBalance - amount1;

        bool sent1 = treasuryWallet.send(amount1);
        require(sent1, "Failed to send amount1");

        bool sent2 = nemusWallet.send(amount2);
        require(sent2, "Failed to send amount1");
    }

    function uri(uint256 _id) public view override returns (string memory) {
            require(totalSupply(_id) > 0, "URI: nonexistent token");
            return string(abi.encodePacked(super.uri(_id), mintTickets[_id].metadataHash));
    } 
}