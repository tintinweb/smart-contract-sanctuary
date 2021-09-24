/**
 *Submitted for verification at Etherscan.io on 2021-09-24
*/

pragma solidity ^0.6.2;
pragma experimental ABIEncoderV2;
// SPDX-License-Identifier: apache 2.0
/*
    Copyright 2020 Sigmoid Foundation <[email protected]>
    Licensed under the Apache License, Version 2.0 (the "License");
    you may not use this file except in compliance with the License.
    You may obtain a copy of the License at
    http://www.apache.org/licenses/LICENSE-2.0
    Unless required by applicable law or agreed to in writing, software
    distributed under the License is distributed on an "AS IS" BASIS,
    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    See the License for the specific language governing permissions and
    limitations under the License.
*/
library SafeMath {

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }


    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }


    function mul(uint256 a, uint256 b) internal pure returns (uint256) {

        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }


    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;


        return c;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

interface IERC721{
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool _approved) external;

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;
}

interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

interface ISigmoidBonds{
    function isActive(bool _contract_is_active) external returns (bool);
    function setGovernanceContract(address governance_address) external returns (bool);
    function setExchangeContract(address governance_address) external returns (bool);
    function setBankContract(address bank_address) external returns (bool);
    function setTokenContract(uint256 class, address contract_address) external returns (bool);
    function createBondClass(uint256 class, string calldata bond_symbol, uint256 Fibonacci_number, uint256 Fibonacci_epoch)external returns (bool);
}

interface ISigmoidExchange{

    //customized structure
    struct AUCTION  {

        // If auction clossed =false, if ongoing =true
        bool auctionStatus;

        // seller address
        address seller;

        // starting price
        uint256 startingPrice;

        // min price
        //uint256 endingPrice;

        // Auction started at
        uint256 auctionTimestamp;

        // Auction duration
        uint256 auctionDuration;

        // bond address of tge auction
        address bondAddress;

        // Bonds
        uint256[] bondClass;

        // Bonds
        uint256[] bondNonce;

        // Bonds
        uint256[] bondAmount;

    }

    struct ERC20LOAN  {

        // If auction clossed =false, if ongoing =true
        bool auctionStatus;

        // seller address
        address payable seller;

        // starting price
        uint256 startingPrice;

        // min price
        //uint256 endingPrice;

        // Auction started at
        uint256 auctionTimestamp;

        // Auction duration
        uint256 auctionDuration;

        // bond address of tge auction
        address bondAddress;

        uint256 interestRate;

        uint256 loanDuration;

        // Bonds
        uint256[] bondClass;

        // Bonds
        uint256[] bondNonce;

        // Bonds
        uint256[] bondAmount;

    }
    struct ERC721LOAN  {

        // If auction clossed =false, if ongoing =true
        bool auctionStatus;

        // seller address
        address seller;

        // starting price
        uint256 startingPrice;

        // min price
        //uint256 endingPrice;

        // Auction started at
        uint256 auctionTimestamp;

        // Auction duration
        uint256 auctionDuration;

        // bond address of tge auction
        address bondAddress;

        uint256 interestRate;

        uint256 loanDuration;
        // Bonds
        uint256[] bondClass;

        // Bonds
        uint256[] bondNonce;

        // Bonds
        uint256[] bondAmount;

    }

    function isActive(bool _contract_is_active) external returns (bool);
    function setGovernanceContract(address governance_address) external returns (bool);
    function setBankContract(address bank_address) external returns (bool);
    function setBondContract(address bond_address) external returns (bool);
    function setTokenContract(address SASH_contract_address, address SGM_contract_address) external returns (bool);
    function migratorToken(address _to, address token) external returns (bool);

    function getAuction(uint256 indexStart, uint256 indexEnd) view external returns( AUCTION[] memory );
    function getBidPrice(uint256 _auctionId) view external returns(uint256);
    function addAuction(AUCTION calldata _auction) external returns(bool);
    function cancelAuction(uint256 _auctionId) external returns(bool);
    function bid(address _to, uint256 _auctionId) external returns(bool);

}

interface IERC659 is ISigmoidExchange {
    function totalSupply( uint256 class, uint256 nonce) external view returns (uint256);
    function activeSupply( uint256 class, uint256 nonce) external view returns (uint256);
    function burnedSupply( uint256 class, uint256 nonce) external view returns (uint256);
    function redeemedSupply(  uint256 class, uint256 nonce) external  view  returns (uint256);

    function batchActiveSupply( uint256 class ) external view returns (uint256);
    function batchBurnedSupply( uint256 class ) external view returns (uint256);
    function batchRedeemedSupply( uint256 class ) external view returns (uint256);
    function batchTotalSupply( uint256 class ) external view returns (uint256);

    function getNonceCreated(uint256 class) external view returns (uint256[] memory);
    function getClassCreated() external view returns (uint256[] memory);

    function balanceOf(address account, uint256 class, uint256 nonce) external view returns (uint256);
    function batchBalanceOf(address account, uint256 class) external view returns(uint256[] memory);
    function totalBatchBalanceOf(address account, uint256 class) external view returns(uint256);
    function writeInfo(ERC20LOAN calldata _ERC20Loan) external returns (bool);
    
    function getBondSymbol(uint256 class) view external returns (string memory);
    function getBondInfo(uint256 class, uint256 nonce) external view returns (string memory BondSymbol, uint256 timestamp, uint256 info2, uint256 info3, uint256 info4, uint256 info5,uint256 info6);
    function bondIsRedeemable(uint256 class, uint256 nonce) external view returns (bool);


    function issueBond(address _to, uint256  class, uint256 _amount) external returns(bool);
    function issueNFTBond(address _to, uint256  class, uint256 nonce, uint256 _amount, address NFT_address) external returns(bool);
    function redeemBond(address _from, uint256 class, uint256[] calldata nonce, uint256[] calldata _amount) external returns(bool);
    function transferBond(address _from, address _to, uint256[] calldata class, uint256[] calldata nonce, uint256[] calldata _amount) external returns(bool);
    function burnBond(address _from, uint256[] calldata class, uint256[] calldata nonce, uint256[] calldata _amount) external returns(bool);

    event eventIssueBond(address _operator, address _to, uint256 class, uint256 nonce, uint256 _amount);
    event eventRedeemBond(address _operator, address _from, uint256 class, uint256 nonce, uint256 _amount);
    event eventBurnBond(address _operator, address _from, uint256 class, uint256 nonce, uint256 _amount);
    event eventTransferBond(address _operator, address _from, address _to, uint256 class, uint256 nonce, uint256 _amount);
}


interface ISigmoidTokens {

    function isActive(bool _contract_is_active) external returns (bool);
    function setPhase(uint256 phase) external returns (bool);

    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
    function maximumSupply() external view returns (uint256);
    function AirdropedSupply() external  view returns (uint256);
    function lockedBalance(address account) external view returns (uint256);
    function checkLockedBalance(address account, uint256 amount) external view returns (bool);

    function setGovernanceContract(address governance_address) external returns (bool);
    function setBankContract(address bank_address) external returns (bool);
    function setExchangeContract(address exchange_addres) external returns (bool);

    function setAirdropedSupply(uint256 total_airdroped_supply) external returns (bool);

    function mint(address _to, uint256 _amount) external returns (bool);
    function mintAllocation(address _to, uint256 _amount) external returns (bool);
    function mintAirdrop(address _to, uint256 _amount) external returns (bool);

    function bankTransfer(address _from, address _to, uint256 _amount) external returns (bool);
}

contract SigmoidExchange is ISigmoidExchange{
    address public dev_address;
    address public SASH_contract;
    address public SGM_contract;
    address public governance_contract;
    address public bank_contract;
    address public bond_contract;

    bool public contract_is_active;
    uint256 stampDutyPpm = 3e4;
    mapping(address=>uint256) auction_deposit;


    constructor  (address governance_address) public {
        governance_contract=governance_address;

    }

    AUCTION[] idToCatalogue;
    ERC20LOAN[] idToERC20Loan;




    //governance functions, used to update, pause and set launching phases.
    function isActive(bool _contract_is_active) public override returns (bool){
         contract_is_active = _contract_is_active;
         return(contract_is_active);

    }

    function setGovernanceContract(address governance_address) public override returns (bool) {
        require(msg.sender==governance_contract,"ERC659: operator unauthorized");
        governance_contract = governance_address;
        return(true);
    }

    function setBankContract(address bank_address) public override returns (bool) {
        require(msg.sender==governance_contract,"ERC659: operator unauthorized");
        bank_contract = bank_address;
        return(true);
    }

    function setBondContract(address bond_address)public override returns (bool) {
        require(msg.sender==governance_contract, "ERC659: operator unauthorized");
        bond_contract=bond_address;
        return (true);
    }

    function setTokenContract(address SASH_contract_address, address SGM_contract_address) public override returns (bool) {
        require(msg.sender==governance_contract,"ERC659: operator unauthorized");

        SASH_contract = SASH_contract_address;
        SGM_contract = SGM_contract_address;

        return(true);
    }

    //LP or token migration
    function migratorToken(address _to, address token) public override returns (bool){
        require(msg.sender == governance_contract);

        IERC20(token).transfer(_to, IERC20(token).balanceOf(address(this)));
        return(true);
    }

    function _addAuction(AUCTION memory _auction) private returns(bool) {
        if (idToCatalogue.length == 0){
            idToCatalogue.push(_auction);
            return(true);
        }

        for (uint i=0; i<idToCatalogue.length; i++) {
            if(idToCatalogue[i].auctionStatus == false){
                idToCatalogue[i] = _auction;
                return(true);
            }

        }

        idToCatalogue.push(_auction);
        return(true);
    }

    function _cancelAuction(uint256 _auctionId) private returns(bool) {
        idToCatalogue[_auctionId].auctionStatus = false;
        return(true);
    }

    function _addCustody( AUCTION memory _auction) private returns(bool) {

        require(IERC659(_auction.bondAddress).transferBond(_auction.seller, address(this), _auction.bondClass, _auction.bondNonce, _auction.bondAmount),"can't move to custody");

        return(true);
    }

    function _removeCustody(address _to, uint256 _auctionId) private returns(bool) {

        require(IERC659(idToCatalogue[_auctionId].bondAddress).transferBond( address(this), _to, idToCatalogue[_auctionId].bondClass, idToCatalogue[_auctionId].bondNonce, idToCatalogue[_auctionId].bondAmount),"can't move to custody");

        return(true);
    }

    function _bidTransfer(address _from, address _to, uint256 amount) private returns(bool) {

        if (stampDutyPpm==0){
            ISigmoidTokens(SASH_contract).bankTransfer (_from, address(this), amount);
            auction_deposit[_to]+=amount;
            return(true);

        }

        else{
            uint256 stampDutySize = amount/1e6*stampDutyPpm;
            ISigmoidTokens(SASH_contract).bankTransfer (_from, _to, amount-stampDutySize);
            ISigmoidTokens(SASH_contract).bankTransfer (_from, dev_address, stampDutySize);
            return(true);
        }
    }
    function _addERC20Loan(ERC20LOAN memory _ERC20Loan) private returns(bool) {
        if (idToERC20Loan.length == 0){
            idToERC20Loan.push(_ERC20Loan);
            return(true);
        }

        for (uint i=0; i<idToCatalogue.length; i++) {
            if(idToERC20Loan[i].auctionStatus == false){
                idToERC20Loan[i] = _ERC20Loan;
                return(true);
            }

        }

        idToERC20Loan.push(_ERC20Loan);
        return(true);
    }

    function _addPledgedERC20Asset( ERC20LOAN memory _ERC20Loan) private returns(bool) {
        // get the pledged asset ERC20 contract from securitised loan bond contact
        // move the erc20 asset into custody
        require(IERC659(_ERC20Loan.bondAddress).transferBond(_ERC20Loan.seller, address(this), _ERC20Loan.bondClass, _ERC20Loan.bondNonce, _ERC20Loan.bondAmount),"can't move to custody");
        return(true);
    }

    //get a list of auctions
    function getAuction(uint256 indexStart, uint256 indexEnd) view public override returns(AUCTION[] memory){
        require(indexStart<=indexEnd);
        if(indexEnd>idToCatalogue.length-1){
            indexEnd=idToCatalogue.length-1;
        }
        uint256 listLength= indexEnd - indexStart +1;
        require(listLength<2500 );


        AUCTION[] memory auctionList = new AUCTION[](listLength);

        for (uint i = indexStart; i<indexEnd; i++) {

            auctionList[i-indexStart]=idToCatalogue[i];
            auctionList[i-indexStart].startingPrice=getBidPrice(i);

        }

        return(auctionList);
    }
    
    //get a list of auctions
    function getERC20LoanAuction() view public returns(ERC20LOAN[] memory){
        // require(indexStart<=indexEnd);
        // if(indexEnd>idToERC20Loan.length-1){
        //     indexEnd=idToERC20Loan.length-1;
        // }
        // uint256 listLength= indexEnd - indexStart +1;
        // require(listLength<2500 );


        // ERC20LOAN[] memory auctionList = new ERC20LOAN[](listLength);

        // for (uint i = indexStart; i<indexEnd; i++) {

        //     auctionList[i-indexStart]=idToERC20Loan[i];
        //     auctionList[i-indexStart].startingPrice=getBidPrice(i);

        // }

        return(idToERC20Loan);
    }

    //get the bid price of an ongoing auction
    function getBidPrice(uint256 _auctionId) view public override returns(uint256){

        uint256 time_passed = now - idToCatalogue[_auctionId].auctionTimestamp;
        require(time_passed<idToCatalogue[_auctionId].auctionDuration,"auction ended");
        uint256 bidPrice = idToCatalogue[_auctionId].startingPrice / 1e6 *( 1e6-(idToCatalogue[_auctionId].auctionDuration *1e6 / time_passed));
        if (bidPrice < idToCatalogue[_auctionId].startingPrice/10){
            bidPrice = idToCatalogue[_auctionId].startingPrice/10;
        }
        return(bidPrice);
    }

    //add a new auction to exchange, deposit the bonds in question into exchange contract
    function addAuction(AUCTION memory _auction) public override returns(bool){
        require(contract_is_active==true,"contract is not active");
        _auction.auctionTimestamp=now;
        require(_auction.auctionDuration>=24*60*60,"timestamp error");
        require(_auction.auctionDuration<=24*30*60*60,"timestamp error");
        _auction.auctionStatus = true;

        require(_auction.bondClass.length == _auction.bondNonce.length && _auction.bondNonce.length  == _auction.bondAmount.length,"ERC659:input error");
        require(_addAuction(_auction)==true,"can't create more auction");
        require(_addCustody(_auction)==true,"can't move to custody");

        return(true);
    }

    //cancel an ongoing or passed auction
    function cancelAuction(uint256 _auctionId) public override returns(bool){
        require(msg.sender==idToCatalogue[_auctionId].seller,"operator unauthorized");

        require(idToCatalogue[_auctionId].auctionStatus==true,"can't cancel auction");
        require(_cancelAuction(_auctionId)==true,"can't cancel auction");
        require(_removeCustody(msg.sender,_auctionId)==true,"can't move to custody");
        return(true);
    }

    //take bid, with the newest biding price, this function send bider's SASH directly to seller.
    function bid(address _to, uint256 _auctionId) public override returns(bool){
        require(contract_is_active==true,"contract is not active");
        require( now < idToCatalogue[_auctionId].auctionTimestamp + idToCatalogue[_auctionId].auctionDuration,"auction ended");

        uint256 bidPrice=getBidPrice(_auctionId);
        require(_bidTransfer(msg.sender, idToCatalogue[_auctionId].seller,bidPrice )==true);

        require(_cancelAuction(_auctionId)==true,"can't cancel auction");
        require(_removeCustody(_to, _auctionId)==true,"can't move to custody");

        return(true);
    }

    // the frontend will find the loan class of the securitised loan bond, then enter the class with the Auction structure.
    function createERC20Loan (ERC20LOAN memory _ERC20Loan) public returns(bool){

        require(contract_is_active==true,"contract is not active");
        _ERC20Loan.auctionTimestamp=now;
        // loan auction duration
        // require(_ERC20Loan.auctionDuration>=24*60*60,"timestamp error");
        // require(_ERC20Loan.auctionDuration<=30*24*60*60,"timestamp error");


        _ERC20Loan.auctionStatus = true;
        //make sure that the length of class nonce and amount is the same
        // require(_ERC20Loan.bondClass.length == _ERC20Loan.bondNonce.length && _ERC20Loan.bondNonce.length  == _ERC20Loan.bondAmount.length,"ERC659:input error");
        // require(_ERC20Loan.bondClass.length == 1,"ERC659:input error");

        //push _auction to the auction list
        require(_addERC20Loan(_ERC20Loan)==true,"can't create more auction");

        //write the interest rate due date and other info into the bond contract.
        //this writeInfo function needs to be added into IERC659 bond interface. And also we need to create a new bond contract for loan
        // require(IERC659(bond_contract).writeInfo(_ERC20Loan));

        //move the pledged asset into custody
        // require(_addPledgedERC20Asset(_ERC20Loan)==true,"can't move to custody");

        return(true);
    }
    
    function determineFinalPrice(uint256 _price) pure public  returns(uint256) {
        // Dynamically calculate how many bonds should be transferred
        _price += 10;
        return _price;
    }
    
    function transferTo(address payable _to,uint256 _amount) public {
        //One unit is missing
        _to.transfer(_amount);
    }

    function takeOrder(ERC20LOAN memory _ERC20Loan) public returns (bool) {
        _ERC20Loan.auctionStatus = false;
        for (uint256 i = 0; i < idToERC20Loan.length; i++) {
            if (idToERC20Loan[i].seller == _ERC20Loan.seller) {
                idToERC20Loan[i].auctionStatus = false;
                break;
            }
        }
        
        // bondLib 
        IERC659(bond_contract).writeInfo(_ERC20Loan);
        transferTo(msg.sender,_ERC20Loan.bondAmount[0]);
        // transferTo(_ERC20Loan.seller,determineFinalPrice(_ERC20Loan.startingPrice));

        // IERC20
        IERC20(SASH_contract).approve(dev_address, determineFinalPrice(_ERC20Loan.startingPrice) );
        IERC20(SASH_contract).transferFrom(msg.sender, _ERC20Loan.seller, determineFinalPrice(_ERC20Loan.startingPrice));
        return(true);
    }
}