/**
 *Submitted for verification at Etherscan.io on 2021-05-16
*/

interface IWETH {
    function deposit() external payable;
    function transfer(address to, uint value) external returns (bool);
    function withdraw(uint) external;
}

// SPDX-License-Identifier: MIT
/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
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

interface IDevWallet {
	
	function transferFunds(address recipient, uint wethAmount) external;
	function acceptPayment() external payable;
	
	function setStakeHolderSalary(address stakeHolder, uint newSalary) external;
	function payDay() external;
	function getMySalary() external returns (uint);

	function changeTieBreaker(address newTieBreaker) external;
	function changeAccountant(address newAccountant) external;
	function changeSuperAdmin(address newSuperAdmin) external;
	function getBuilder() external view returns (address);
	function getSuperAdmin() external view returns (address);
	function getTieBreaker() external view returns (address);

	function getCompetitionWalletAddress() external returns(address);
	function getIntemediaryWalletAddress() external returns(address);
	function getRepresentativeQuorumAddress() external returns(address);
	function changeCompetitionWalletAddress(address newAddress) external;
	function changeIntemediaryWalletAddress(address newAddress) external;
	function changeRepresentativeQuorumAddress(address newAddress) external;

	function getMyRole() external view returns (string [7] memory);

	function setAcceptableCurrencies(address [] memory acceptedCurrencies) external;
	function getAcceptableCurrencies() external returns (address [] memory);

	function setTieBreakerWinner(address winningContract) external;
	function getTieBreakerWinner() external view returns(address);
}

interface IRepresentativeQuorum {
	
	function getMyRole() external view returns (string memory);

	function checkQuorumWinner(address supposedWinner) external returns (uint quorumOutcome);
	function isQuorum(uint choice) external view returns (uint quorumOutcome);

	function signForAction(uint choice) external;
	function getLastSignedAction(address repr) external view returns (uint);
	function isSigned(address representativeAddr, uint choice) external view returns (bool isSigned) ;

	function getRepresentativeCount() external view returns(uint count);
	function getRepresentativeAtIndex(uint index) external view returns(address representative) ;
	function deleteRepresentative(address deletedRepresentative) external ;
	function addRepresentative(address newRepresentative, bool newV3, address newSwapToContract, address newRepresentingContract, address newSendingAddress) external;

	function getSwapToContract(address reprAddress) external view returns (address);
	function getV3(address reprAddress) external view returns (bool);
	function getRepresentingContract(address reprAddress) external view returns (address);
	function getSendingAddress(address reprAddress) external view returns (address);
	function getSignedWinner(address reprAddress) external view returns (address);

	function reset() external;

	function getCurrentContractsAccepted() external view returns (address [] memory);
	function getRepresentativeForContract(address contractAddr) external view returns (address);

	function setWinningRepresentative() external returns (bool);
	function getWinningRepresentative() external view returns (address);


}

contract RepresentativeQuorum is IRepresentativeQuorum {

	enum ActionChoices { AddRepresentative, DeleteRepresentative, ReleaseWinnings}
	enum QuorumOutcome { YES, TIE, NO }

	address[] representatives;
	mapping (address => uint) choices;
	mapping (address => uint) lastSigned;
	mapping (address => bool) v3;
	mapping (address => address) swapToContract;
	mapping (address => address) representingContract;
	mapping (address => address) sendingAddress;
	mapping (address => address) signedWinner;

	address winningRepresentative;

	IDevWallet devWallet;

	constructor(address devWalletAddr){
		devWallet = IDevWallet(devWalletAddr);	
	}

	modifier onlyRelated(){
		bool relatedWallet = msg.sender == devWallet.getCompetitionWalletAddress();
		bool repr = lastSigned[msg.sender] != 0;
		bool admin = msg.sender == devWallet.getSuperAdmin() || msg.sender == devWallet.getTieBreaker();
		//bool builder = msg.sender == devWallet.getBuilder();
		require(relatedWallet || repr || admin /* || builder */);
		_;
	}
	modifier onlyCompetitionWallet(){
		require(msg.sender == devWallet.getCompetitionWalletAddress(), "Only the competitionWallet can perform this request");
		_;
	}
	modifier onlyTieBreaker(){
		require(msg.sender == devWallet.getTieBreaker(), "Only the tiebreaker can make this request");
		_;
	}
	modifier onlySuperAdmin(){
		require(msg.sender == devWallet.getSuperAdmin(), "Only the superAdmin can make this request");
		_;
	}
	modifier onlyTieBreakerAndAbove(){
		require(msg.sender == devWallet.getTieBreaker() || msg.sender == devWallet.getSuperAdmin() , "Only the tiebreaker can make this request");
		_;
	}
	modifier onlyRepresentative(){
		require(lastSigned[msg.sender] != 0, "Only a current representative can make this request");
		_;
	}


	modifier onlyRepresentativeAndAbove(){
		require(((msg.sender == devWallet.getTieBreaker()) || (msg.sender == devWallet.getSuperAdmin()) || (lastSigned[msg.sender] != 0)), "Only a current representative / abovecan make this request");
		_;
	}

	function getMyRole() public view override returns (string memory){
		if ( lastSigned[msg.sender] != 0) return "representative";
		return "normie";
	}

	function checkQuorumWinner(address supposedWinner) public override returns (uint quorumOutcome) {
		uint voteCounter = 0;
		for (uint i = 0 ; i < representatives.length; i++){
			if (isSigned(representatives[i], uint(ActionChoices.ReleaseWinnings)) && signedWinner[representatives[i]] == supposedWinner){
				voteCounter +=1;
			}
		}
		
		if (voteCounter > representatives.length/2) {
			winningRepresentative = getRepresentativeForContract(supposedWinner);
			return (uint(QuorumOutcome.YES));
		}
		else if (voteCounter < representatives.length/2){
			return (uint(QuorumOutcome.NO));
		}
		else {
			if (devWallet.getTieBreakerWinner() == supposedWinner) {
				winningRepresentative = getRepresentativeForContract(supposedWinner);
				return (uint(QuorumOutcome.YES));
			} 
			else return (uint(QuorumOutcome.NO));
		}

	}


	function isSigned(address representativeAddr, uint choice) public view override onlyRepresentativeAndAbove returns (bool isSigned) {
		require(lastSigned[representativeAddr] != 0, "Person you are enquiring about doesn't seem to be a representative");
		if (lastSigned[representativeAddr] < block.timestamp - 8400 ){
			return false;
		}
		return choices[representativeAddr] == choice;
	}


	function isQuorum(uint choice) public view override returns (uint quorumOutcome){
		if (representatives.length == 0) return uint(QuorumOutcome.TIE);
		uint voteCounter = 0;
		for (uint i = 0 ; i < representatives.length; i++){
			if (isSigned(representatives[i], choice)){
				voteCounter +=1;
			}
		}
		if (voteCounter > representatives.length/2) {
			return (uint(QuorumOutcome.YES));
		}
		else if (voteCounter < representatives.length/2){
			return (uint(QuorumOutcome.NO));
		}
		else return (uint(QuorumOutcome.TIE));
	}

	function addRepresentative(address newRepresentative, bool newV3, address newSwapToContract, address newRepresentingContract, address newSendingAddress) public override onlySuperAdmin{
		bool isQuorumForAddition = isQuorum(uint(ActionChoices.AddRepresentative)) == 0;

		if (isQuorumForAddition || representatives.length <= 2){
			representatives.push(newRepresentative);
			choices[newRepresentative] = uint(ActionChoices.AddRepresentative);
			lastSigned[newRepresentative] = block.timestamp;
			v3[newRepresentative] = newV3;
			swapToContract[newRepresentative] = newSwapToContract;
			representingContract[newRepresentative] = newRepresentingContract;
			sendingAddress[newRepresentative] = newSendingAddress;
			signedWinner[newRepresentative] = address(0);
		}
	}

	function deleteRepresentative(address deletedRepresentative) public override onlySuperAdmin{

		bool isQuorumForDeletion = isQuorum(uint(ActionChoices.DeleteRepresentative)) == 0;

		if (isQuorumForDeletion){
			for (uint i = 0; i < representatives.length; i++){
				if (representatives[i] == deletedRepresentative){
					representatives[i] = representatives[representatives.length -1];
					delete representatives[representatives.length-1];
					delete choices[deletedRepresentative];
					delete lastSigned[deletedRepresentative];
					delete v3[deletedRepresentative];
					delete swapToContract[deletedRepresentative];
					delete representingContract[deletedRepresentative];
					delete sendingAddress[deletedRepresentative];
					delete signedWinner[deletedRepresentative];
				}
			}
		}
	}

	function setWinningRepresentative() public override onlySuperAdmin returns (bool){

		for (uint i = 0; i < representatives.length; i++) {

			address currentRepresentingContract = representatives[i];
			uint winning = checkQuorumWinner(currentRepresentingContract);
			if (winning == 0) {
				winningRepresentative = representatives[i];
				return true;
			}
		}
		return false;
	}
	function getWinningRepresentative() public view override returns (address){
		return winningRepresentative;
	}


	function getRepresentativeAtIndex(uint index) public view override returns(address representative) {
        return representatives[index];
    }

    function getRepresentativeCount() public view override returns(uint count) {
        return representatives.length;
    }


	function getLastSignedAction(address repr) public view override onlyRepresentativeAndAbove returns (uint){

		require(lastSigned[repr] > block.timestamp - 8400, "Doesn't seem to have signed recently");

		return choices[repr];
	}

	function signForAction(uint choice) public override onlyRepresentative{
		lastSigned[msg.sender] = block.timestamp;
		choices[msg.sender] = choice;
	}

	function getV3(address reprAddress) public view override returns (bool){
		return v3[reprAddress];
	}

	function getSwapToContract(address reprAddress) public view override returns (address){
		return swapToContract[reprAddress];
	}
	function getRepresentingContract(address reprAddress) public view override returns (address){
		return representingContract[reprAddress];
	}		
	function getSendingAddress(address reprAddress) public view override returns (address){
		return sendingAddress[reprAddress];
	}
	function getSignedWinner(address reprAddress) public view override returns (address){
		return signedWinner[reprAddress];
	}

	function reset() public override onlyCompetitionWallet{
		for (uint i = 0; i < representatives.length; i++){
			delete choices[representatives[i]];
			delete lastSigned[representatives[i]];
			delete v3[representatives[i]];
			delete swapToContract[representatives[i]];
			delete representingContract[representatives[i]];
			delete sendingAddress[representatives[i]];
			delete signedWinner[representatives[i]];
			delete winningRepresentative;
		}


		delete representatives;

	}


	function getCurrentContractsAccepted() public view override returns (address [] memory){
		address [] memory contracts = new address[](representatives.length);
		for (uint i = 0; i < representatives.length; i++){
			contracts[i] = representingContract[representatives[i]];
		}	
		return contracts;
	}

	function getRepresentativeForContract(address contractAddr) public view override returns (address) {
		for (uint i = 0; i < representatives.length; i++){
			if (representingContract[representatives[i]] == contractAddr){
				return representatives[i];
			}
		}	
	}

}