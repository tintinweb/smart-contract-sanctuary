/**
 *Submitted for verification at Etherscan.io on 2021-12-30
*/

//SPDX-License-Identifier: GPL v3

pragma solidity >=0.8.0;



abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

abstract contract Ownable is Context {
    address private _owner;
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    constructor() {
        _setOwner(_msgSender());
    }
    function owner() public view virtual returns (address) {
        return _owner;
    }
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }
    function renounceOwnership() public virtual onlyOwner {
        _setOwner(address(0));
    }
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }
    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}


interface IERC721Receiver {
    function onERC721Received(address operator, address from, uint256 tokenId, bytes calldata data) external returns (bytes4);
}

interface BDERC721 {
	function balanceOf(address wallet) external view returns(uint256);
	function ownerOf(uint256 tokenID) external view returns(address);
	function getApproved(uint256 tokenId) external view returns (address operator);
	function safeTransferFrom(address from,address to,uint256 tokenId) external;
}

interface BDERC20 {
	function balanceOf(address wallet) external view returns(uint256);
	function allowance(address owner, address spender) external view returns(uint256);
	function transferFrom(address owner, address spender, uint256 amount) external returns(bool);
	function transfer(address reciever, uint256 amount) external returns(bool);
	function burnFrom(address owner, address spender, uint256 amount) external returns(bool);
}

contract BasementStaking is Ownable {

	struct NFTStaking {
		// check if the NFT contract address is supported
		bool supported;
		// the cost of the next level
		uint256 advanceCost;
		// the reward of the next level
		uint256 tsReward;
		// maximum staking amount
		uint256 maxStakingS;
		// min staking time before reward
		uint256 tsForReward;
		// the addresses of all the stakers for this NFT contract
		address[] stakers;
	}

	mapping(address => NFTStaking) supportedNFTs;

	address public EXP;
	uint256 private baseCost = 1 ether;
	

	struct Stakes {
		address nftOwner;
		uint256 lockTS;
		uint256 lockAccumlation;
		uint256 tokenLevel;
		bool isStaked;
	}

    function onERC721Received(address operator, address from, uint256 tokenId, bytes calldata data) public pure returns(bytes4){
        return(IERC721Receiver.onERC721Received.selector);
    }

	constructor(address experience){
		EXP = experience;
	}

	// nft contract => tokenids
	mapping(address => mapping(uint256 => Stakes)) NFTstakes;
	// nft contract => wallet => nfts
	mapping(address => mapping(address => uint256[])) walletNFTs;

	event NFTUpgraded(address indexed NFTcontract, address indexed NFTOwner, uint256 tokenID, uint256 oldLevel, uint256 newLevel);

	function changeStakingProps(address nftContract, uint256 _advCost, uint256 _reward, uint256 _maxStakeTime, uint256 _timeToReward) external onlyOwner {
		supportedNFTs[nftContract].supported = true;
		supportedNFTs[nftContract].advanceCost = _advCost*baseCost;
		supportedNFTs[nftContract].tsReward = _reward*baseCost;
		supportedNFTs[nftContract].maxStakingS = _maxStakeTime;
		supportedNFTs[nftContract].tsForReward = _timeToReward;
	}

	function UnsupportNFT(address nftContract) external onlyOwner {
		supportedNFTs[nftContract].supported = false;
	}

	function recieve20Payment(address wallet, uint256 amount) internal returns(bool){
		require(BDERC20(EXP).allowance(wallet, address(this)) >= amount, "DwellersStaking: Need to approve EXP");
		require(BDERC20(EXP).transferFrom(wallet, address(this), amount), "DwellersStaking: Need to transfer EXP");
		return true;
	}

	function burn20Payment(address wallet, uint256 amount) internal returns(bool){
		require(BDERC20(EXP).allowance(wallet, address(this)) >= amount, "DwellersStaking: Need to approve EXP");
		require(BDERC20(EXP).burnFrom(wallet, address(this), amount), "DwellersStaking: Need to BURN EXP");
		return true;
	}

	function send20Payment(address wallet, uint256 amount) internal returns(bool){
		require(BDERC20(EXP).balanceOf(address(this)) >= amount, "DwellersStaking: Not enough funds");
		require(BDERC20(EXP).transfer(wallet, amount), "DwellersStaking: Cannot transfer funds");
		return true;
	}

	function recieve721Token(address nftContract, address wallet, uint256 tokenID) internal returns(bool) {
		require(BDERC721(nftContract).ownerOf(tokenID) == wallet, "DwellersStaking: Must be the owner of the NFT to stake");
		require(BDERC721(nftContract).getApproved(tokenID) == address(this), "DwellersStaking: Must approve BasementStaking to stake");
		BDERC721(nftContract).safeTransferFrom(wallet, address(this), tokenID);
		return true;
	}

	function send721Token(address nftContract, address wallet, uint256 tokenID) internal returns(bool) {
		require(BDERC721(nftContract).ownerOf(tokenID) == address(this), "DwellersStaking: does NOT own this NFT");
		BDERC721(nftContract).safeTransferFrom(address(this), wallet, tokenID);
		return true;
	}

	function isNFTcontractSupported(address nftContract) public view returns(bool){

		return(supportedNFTs[nftContract].supported);
	}

	function getAllNFTsStaked(address nftContract, address wallet) public view returns(uint256[] memory allNFTs){
		require(isNFTcontractSupported(nftContract), "DwellersStaking: This NFT contract is not supported");
		return(walletNFTs[nftContract][wallet]);
	}

	function getNFTowner(address nftContract, uint256 tokenID) public view returns(address){
		if(NFTstakes[nftContract][tokenID].nftOwner == address(0)){
			address _owner = BDERC721(nftContract).ownerOf(tokenID);
			require(_owner != address(0),"This NFT has not been minted yet");
			return _owner;
		}
		return(NFTstakes[nftContract][tokenID].nftOwner);
	}

	function getNFTLevel(address nftContract, uint256 tokenID) public view returns(uint256){

		return(NFTstakes[nftContract][tokenID].tokenLevel);
	}

	function calcUpgradeLevels(uint256 amount, uint256 perlevelCost) public pure returns(uint256){
		return((amount/perlevelCost));
	}

	function upgradeDweller(address nftContract, uint256 tokenID, uint256 expAmount) external {
		require(isNFTcontractSupported(nftContract), "DwellersStaking: This NFT contract is not supported");
		uint256 levelsCount = calcUpgradeLevels(expAmount, supportedNFTs[nftContract].advanceCost);
		require(levelsCount != 0, "Cannot upgrade 0 levels, increase EXP");
		require(burn20Payment(msg.sender, expAmount), "DwellersStaking: Need to spend EXP to upgrade");
		require(getNFTowner(nftContract, tokenID) == msg.sender, "DwellersStaking: only the owner of the NFT can upgrade");
		uint256 currentLevel = getNFTLevel(nftContract, tokenID);
		NFTstakes[nftContract][tokenID].tokenLevel += levelsCount;
		emit NFTUpgraded(nftContract, msg.sender, tokenID, currentLevel, (currentLevel+levelsCount));
	}

	function getAllNFTStakers(address nftContract) public view returns(address[] memory){
		require(isNFTcontractSupported(nftContract), "DwellersStaking: This NFT contract is not supported");
		return(supportedNFTs[nftContract].stakers);
	}

	function removeFromNFTStakers(address nftContract, address wallet) internal {
		address[] storage _stakers = supportedNFTs[nftContract].stakers;
		uint256 index =0;
		for(uint256 i=0; i<_stakers.length; i++){
			if(_stakers[i] == wallet){
				index = i;
				break;
			}
		}
		if(index == _stakers.length-1){
			_stakers.pop();
		}else{
			for(uint256 i=index; i<_stakers.length-1; i++){
				_stakers[i] = _stakers[i+1];
			}
			_stakers.pop();
		}
	}

	function removeFromWalletNFTs(address nftContract, address wallet, uint256 tokenID) internal {
		uint256[] storage _wNFTs = walletNFTs[nftContract][wallet];
		uint256 index = 0;
		for(uint256 i=0; i<_wNFTs.length; i++){
			if(_wNFTs[i] == tokenID){
				index = i;
				break;
			}
		}
		for(uint256 i=index; i<_wNFTs.length-1; i++){
			_wNFTs[i] = _wNFTs[i+1];
		}
		_wNFTs.pop();
	}

	function _safeRemoveStake(address nftContract, address wallet, uint256 tokenID) internal {
		Stakes storage _stake = NFTstakes[nftContract][tokenID];
		_stake.isStaked = false;
		_stake.nftOwner = address(0);
		_stake.lockTS = uint256(0);
		removeFromWalletNFTs(nftContract, wallet, tokenID);
		if(walletNFTs[nftContract][wallet].length == 0){
			removeFromNFTStakers(nftContract, wallet);			
		}
	}

	function _safeAddStake(address nftContract, address wallet, uint256 tokenID) internal {
		Stakes storage _stake = NFTstakes[nftContract][tokenID];
		require(_stake.lockAccumlation <= supportedNFTs[nftContract].maxStakingS, "DwellersStaking: Cannot stake more than 2 years");
		_stake.isStaked = true;
		_stake.nftOwner = wallet;
		_stake.lockTS = block.timestamp;
		walletNFTs[nftContract][wallet].push(tokenID);
		supportedNFTs[nftContract].stakers.push(wallet);
	}

	function unstakeDweller(address nftContract, uint256 tokenID) external {
		require(isNFTcontractSupported(nftContract), "DwellersStaking: This NFT contract is not supported");
		Stakes memory _stake = NFTstakes[nftContract][tokenID];
		require(_stake.nftOwner == msg.sender, "DwellersStaking: cannot unstake an NFT that does not belong to the sender");
		NFTStaking memory stakingProps = supportedNFTs[nftContract];
		if(_stake.lockAccumlation < stakingProps.maxStakingS){
			require(burn20Payment(msg.sender, calcUnstakingFee(_stake.lockAccumlation, stakingProps.tsForReward, stakingProps.tsReward)), "DwellersStaking: need to pay 33% of accumlated tokens to unstake early");
		}
		_safeRemoveStake(nftContract, msg.sender, tokenID);
	}

	function stakeDweller(address nftContract, uint256 tokenID) external {
		require(isNFTcontractSupported(nftContract), "DwellersStaking: This NFT contract is not supported");
		require(recieve721Token(nftContract, msg.sender, tokenID), "DwellersStaking: Unable to stake this NFT");
		_safeAddStake(nftContract, msg.sender, tokenID);
	}

	function calcReward(uint256 lockTs, uint256 ts, uint256 rewardTime, uint256 rewardAmount) public pure returns(uint256 reward, uint256 accumlation){
		uint256 deltaT = (ts - lockTs);
		reward = ((deltaT/rewardTime)*rewardAmount);
		accumlation = ((deltaT/rewardTime)*rewardTime);
	}

	function calcUnstakingFee(uint256 accumlation, uint256 rewardTime, uint256 rewardAmount) public pure returns(uint256 unstakingFee){

		return((accumlation*rewardAmount*33)/(rewardTime*100));
	}

	function avalToClaim(address nftContract, address wallet) public view returns(uint256 rewardable){
		require(isNFTcontractSupported(nftContract), "DwellersStaking: This NFT contract is not supported");
		uint256[] memory _wallet = getAllNFTsStaked(nftContract, wallet);
		require(_wallet.length > 0, "DwellersStaking: You do not have any staked NFTs");
		uint256 ts = block.timestamp;
		NFTStaking memory stakingProps = supportedNFTs[nftContract];
		for(uint256 i=0; i<_wallet.length; i++){
			if((NFTstakes[nftContract][_wallet[i]].lockTS + stakingProps.tsForReward <= ts) && (NFTstakes[nftContract][_wallet[i]].lockAccumlation < stakingProps.maxStakingS)){
				Stakes memory _stake = NFTstakes[nftContract][_wallet[i]];
				(uint256 _rwrd,) = calcReward(_stake.lockTS, ts, stakingProps.tsForReward, stakingProps.tsReward);
				rewardable += _rwrd;
			}
		}
	}

	function getStakes(address nftContract, uint256 tokenID) public view returns(Stakes memory){
		require(isNFTcontractSupported(nftContract), "DwellersStaking: This NFT contract is not supported");
		return(NFTstakes[nftContract][tokenID]);
	}

	function ClaimStakingRewards(address nftContract) external {
		require(isNFTcontractSupported(nftContract), "DwellersStaking: This NFT contract is not supported");
		uint256[] memory _wallet = getAllNFTsStaked(nftContract, msg.sender);
		require(_wallet.length > 0, "DwellersStaking: You do not have any staked NFTs");
		uint256 rewardable = 0;
		uint256 ts = block.timestamp;
		NFTStaking memory stakingProps = supportedNFTs[nftContract];
		for(uint256 i=0; i<_wallet.length; i++){
			if((NFTstakes[nftContract][_wallet[i]].lockTS + stakingProps.tsForReward <= ts) && (NFTstakes[nftContract][_wallet[i]].lockAccumlation < stakingProps.maxStakingS)){
				Stakes storage _stake = NFTstakes[nftContract][_wallet[i]];
				(uint256 _rwrd, uint256 _rAcc) = calcReward(_stake.lockTS, ts ,stakingProps.tsForReward, stakingProps.tsReward);
				rewardable += _rwrd;
				_stake.lockTS = ts;
				_stake.lockAccumlation += _rAcc;
			}
		}
		require(send20Payment(msg.sender, rewardable), "DwellersStaking: Unable to reward staking");
	}


}