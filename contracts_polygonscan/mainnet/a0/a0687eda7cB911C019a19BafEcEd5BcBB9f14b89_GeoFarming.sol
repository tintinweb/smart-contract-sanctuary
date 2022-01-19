/**
 *Submitted for verification at polygonscan.com on 2022-01-19
*/

/*
  /$$$$$$                                          /$$                    
 /$$__  $$                                        | $$                    
| $$  \__/  /$$$$$$   /$$$$$$   /$$$$$$   /$$$$$$ | $$ /$$   /$$          
| $$ /$$$$ /$$__  $$ /$$__  $$ /$$__  $$ /$$__  $$| $$| $$  | $$          
| $$|_  $$| $$$$$$$$| $$  \ $$| $$  \ $$| $$  \ $$| $$| $$  | $$          
| $$  \ $$| $$_____/| $$  | $$| $$  | $$| $$  | $$| $$| $$  | $$          
|  $$$$$$/|  $$$$$$$|  $$$$$$/| $$$$$$$/|  $$$$$$/| $$|  $$$$$$$          
 \______/  \_______/ \______/ | $$____/  \______/ |__/ \____  $$          
                              | $$                     /$$  | $$          
                              | $$                    |  $$$$$$/          
                              |__/                     \______/           
       /$$$$$$$$                                   /$$                    
      | $$_____/                                  |__/                    
      | $$        /$$$$$$   /$$$$$$  /$$$$$$/$$$$  /$$ /$$$$$$$   /$$$$$$ 
      | $$$$$    |____  $$ /$$__  $$| $$_  $$_  $$| $$| $$__  $$ /$$__  $$
      | $$__/     /$$$$$$$| $$  \__/| $$ \ $$ \ $$| $$| $$  \ $$| $$  \ $$
      | $$       /$$__  $$| $$      | $$ | $$ | $$| $$| $$  | $$| $$  | $$
      | $$      |  $$$$$$$| $$      | $$ | $$ | $$| $$| $$  | $$|  $$$$$$$
      |__/       \_______/|__/      |__/ |__/ |__/|__/|__/  |__/ \____  $$
                                                                 /$$  \ $$
                                                                |  $$$$$$/
                                                                 \______/ 


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
        _transferOwnership(_msgSender());
    }

    function owner() public view virtual returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }


    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

interface GeoPolyNFT {

	function getMintingString(uint256 tokenID) external view returns(string memory);
	function balanceOf(address wallet, uint256 tokenID) external returns(uint256);
    function isApprovedForAll(address account, address operator) external view returns (bool);
    function safeTransferFrom(address from,address to,uint256 id,uint256 amount, bytes calldata data) external;
	function getWalletNFTs(address wallet) external view returns(uint256[] memory);
}

interface Geos20 {
	function decimals() external view returns(uint256);
    function transferFrom(address sender,address recipient,uint256 amount) external returns (bool);    
    function allowance(address owner, address spender) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function balanceOf(address account) external view returns (uint256);
}

library GeopolyFarmingHelper {
	function findIndexInArr(uint256 val, uint256[] memory arr) public pure returns(bool,uint256){
        for(uint256 i=0; i<arr.length; i++){
            if(val == arr[i]){
                return(true, i);
            }
        }
        return(false, 0);
    }
}



abstract contract GeopolyRoles is Ownable {
    mapping(address => bool) private geopolyContracts;
    mapping(address => bool) private geopolyAdmins;

    function addToGeopolyContracts(address _nContract) public onlyOwner {
        geopolyContracts[_nContract] = true;
    }

    function removeFromGeopolyContracts(address _contract) public onlyOwner {
        geopolyContracts[_contract] = false;
    }

    function addToGeopolyAdmins(address _nAdmin) public onlyOwner {
    	geopolyAdmins[_nAdmin] = true;
    }

    function removeFromGeopolyAdmins(address _admin) public onlyOwner {
    	geopolyAdmins[_admin] = false;
    }

    modifier isAdmin(){
    	require(geopolyAdmins[_msgSender()], "GeopolyRoles: Address not admin");
        _;
    }

    modifier isGeopolyContract() {
        require(geopolyContracts[_msgSender()], "GeopolyRoles: Address not a geopoly contract");
        _;
    }
}

interface GeoSpeical {
    function doAll(string calldata _in) external pure returns(uint256, uint256, uint256, string memory, string memory);
}



contract GeoFarming is GeopolyRoles {

	event FarmingStarted(uint256 tokenID, address owner, uint256 unlockTime, uint256 spinsAmount);
	event FarmingHarvested(uint256 tokenID, address owner, uint256 timestamp, uint256 spinsAmount);
	event SpinsPurchased(uint256 amount, address owner);

	// address for the NFT contract `ERC1155`
	address NFT = 0x0b72a80C151DeC838Cb6fBCE002c09eD35897345;
	// current status for farming
	bool private farmingStatus;
	// farming fee, once paid on each NFT farm done
	uint256 farmingFee;
	// basis for calculating reward
	uint256 baseMultiplier = 1;
	uint256 baseDivisor = 1;
	uint256 baseOffset = 0;
	// price basis for tokens of 18 decimals
	uint256 priceBasis = 1 ether;
	// Mapping for each address on how many geospins
	mapping(address => uint256) _spins;
	// Mapping for each token supported how much for 1 GeoSpin
	mapping(address => uint256) _costs;
	// nft locking time
	uint256 nftLockTime = 120;
	// the return value of the selector
	bytes4 _ERC1155Selector = 0xf23a6e61;
	// a structure for all the different farmings
	struct Farmings {
		address owner;
		uint256 lockTs;
		uint256 unlockTs;
		uint256 spinReward;
	}

	// Mapping for each token to Farmings
	mapping(uint256 => Farmings) _farmings;
	// a reference for all the tokens currently farming
	uint256[] tokensFarming;
	// sale of geoSpins allowed
	bool geoSpinSales;
    // library contract address
    address geospecial = 0x44DA64602f77f7Caded40D71E0f1A252E6800064;
    // change the status of the Geospin sales for tokens
	function changeGeoSpinSaleStatus(bool _nStatus) public isAdmin {
		geoSpinSales = _nStatus;
	}

	function changeRewardBasis(uint256 _nBaseMultiplier, uint256 _nBaseDivisor, uint256 _nBaseOffset) public isAdmin {
		baseMultiplier = _nBaseMultiplier;
		baseDivisor = _nBaseDivisor;
		baseOffset = _nBaseOffset;
	}

	function changeFarmingFee(uint256 _nFee) public isAdmin {
		farmingFee = _nFee;
	} 

	function changeFarmingStatus(bool _farmingStatus) public isAdmin {
		farmingStatus = _farmingStatus;
	}

	function changeNFTFarmingPeriod(uint256 _nFarmingPeriod) public isAdmin{
		nftLockTime = _nFarmingPeriod;
	}

	function nftFarmingPeriod() public view returns(uint256){
		return(nftLockTime);
	}

	// check if tokenID is farming
	function isNFTFarming(uint256 tokenID) public view returns(bool){
		return(_farmings[tokenID].lockTs > 0);
	}

	function spinsReward(uint256 tokenID) public view returns(uint256){
		return(_farmings[tokenID].spinReward);
	}

	// check farming time remaining will return a timestamp in seconds of when is unlocked
	function farmingTime(uint256 tokenID) public view returns(uint256){
		return(_farmings[tokenID].unlockTs);
	}
	// check the original NFT owner of the tokenID
	function nftOwner(uint256 tokenID) public view returns(address){
		require(isNFTFarming(tokenID), "GeopolyFarms: This token is not currently farming");
		return(_farmings[tokenID].owner);
	}
	// safe add farming to the tokenID
	function _safeAddFarming(uint256 tokenID, address owner, uint256 lockTS, uint256 unlockTS) internal {
		_farmings[tokenID] = Farmings(owner, lockTS, unlockTS, getRewards(tokenID));
		tokensFarming.push(tokenID);
	}
	// safe remove farming from the tokenID
	function _safeRemoveFarming(uint256 tokenID) internal {
		_safeAddSpins(_farmings[tokenID].spinReward, _farmings[tokenID].owner);
		_farmings[tokenID] = Farmings(address(0), 0, 0, 0);
		(bool sucess, uint256 index) = GeopolyFarmingHelper.findIndexInArr(tokenID, tokensFarming);
		if(sucess){
			delete(tokensFarming[index]);
		}else{
			revert("Cannot find index");
		}
	}

	// remove the 0s stuck in the array from deletion to free up gas for users
	function cleanUp() external {
        uint256 _count = 0;
        for(uint256 i=0; i<tokensFarming.length; i++){
            if(tokensFarming[i] != 0){
                _count +=1;
            }
        }
        uint256[] memory _nAllTokens = new uint256[](_count);
        uint256 _index = 0;
        for(uint256 i=0; i<tokensFarming.length; i++){
            if(tokensFarming[i] != 0){
                _nAllTokens[_index] = tokensFarming[i];
                _index +=1;
            }
        }
        tokensFarming = _nAllTokens;
	}

	// initiate the farm 
	function Farm(uint256 tokenID) external payable {
		require(farmingStatus, "GeopolyFarms: Sorry Farming is under maintainance");
		require(!isNFTFarming(tokenID), "GeopolyFarms: This NFT has already started farming");
		require(msg.value >= farmingFee, "GeopolyFarms: You need to pay a farming fee to start farming your NFT");
		require(recieve1155Token(msg.sender, tokenID), "GeopolyFarms: Cannot Farm your NFT");
		_safeAddFarming(tokenID, msg.sender, block.timestamp, (block.timestamp + nftLockTime));

	}
	// harvest the farm initated
	function Harvest(uint256 tokenID) external {
		require(nftOwner(tokenID) == msg.sender, "GeopolyFarms: Cannot harvest an NFT that is not your own");
		require(block.timestamp >= farmingTime(tokenID), "GeopolyFarms: This NFT is not done farming yet");
		require(send1155Token(msg.sender, tokenID), "GeopolyFarms: Cannot send back the NFT");
		_safeRemoveFarming(tokenID);
	}
	//get all the current nfts farming
	function getWalletFarmings(address wallet) public view returns(uint256[] memory walletFarmings){
		uint256 count = 0;
		for(uint256 i=0; i<tokensFarming.length; i++){
			if(_farmings[tokensFarming[i]].owner == wallet){
				count += 1;
			}
		}	
		walletFarmings = new uint256[](count);
		count = 0;
		for(uint256 i=0; i<tokensFarming.length; i++){
			if(_farmings[tokensFarming[i]].owner == wallet){
				walletFarmings[count] = tokensFarming[i];
				count += 1;
			}
		}
	}
	// get all the users NFTs (farming&&notFarming)
	function getWalletNFTs(address owner) public view returns(uint256[] memory allNFTs) {
		uint256[] memory nftsMain = GeoPolyNFT(NFT).getWalletNFTs(owner);
		uint256[] memory nftsFarming = getWalletFarmings(owner);
	 	uint256 _fLen = nftsMain.length;
        uint256 _nLen = nftsFarming.length;
        uint256 _combinedLen = _fLen + _nLen;
        allNFTs = new uint256[](_combinedLen);
        if(_fLen != 0){
            for(uint256 i=0; i<_fLen; i++){
                allNFTs[i] = nftsMain[i];
            }
        }
        if(_nLen != 0){
            if(_fLen != 0){
                for(uint256 i=0; i<_nLen; i++){
                    allNFTs[(_fLen+i)] = nftsFarming[i];
                }
            }else{
                for(uint256 i=0; i<_nLen; i++){
                        allNFTs[i] = nftsFarming[i];
                }
            }
        }
	}


	/**
	 * boring ERC1155 function to acknowledge that GeopolyFarms can receieve ERC1155 tokens
	 */
    function onERC1155Received(address ,address ,uint256 ,uint256 ,bytes calldata) public view returns(bytes4){
    	return(_ERC1155Selector);
    }

	/**
	 * boring ERC1155 function to send tokens
	 */
	function send1155Token(address owner, uint256 tokenID) internal returns(bool) {
		require(GeoPolyNFT(NFT).balanceOf(address(this), tokenID) > 0, "GeopolyFarms: We do not own this NFT.");
		GeoPolyNFT(NFT).safeTransferFrom(address(this), owner, tokenID, 1, "");
		return true;
	}
	/**
	 * boring ERC1155 function to recieve tokens
	 */
	function recieve1155Token(address owner, uint256 tokenID) internal returns(bool) {
		require(GeoPolyNFT(NFT).balanceOf(owner, tokenID) > 0, "GeopolyFarms: Cannot farm NFT you dont own");
		require(GeoPolyNFT(NFT).isApprovedForAll(owner, address(this)), "GeopolyFarms: Need to approve us to farm your NFT");
		GeoPolyNFT(NFT).safeTransferFrom(owner, address(this), tokenID, 1, "");
		return true;
	}
    /**
     * boring ERC20 function to send tokens
     */
    function send20Token(address token, address reciever, uint256 amount) internal returns(bool){
        require(Geos20(token).balanceOf(address(this)) > amount, "No enough balance");
        require(Geos20(token).transfer(reciever, amount), "Cannot currently transfer");
        return true;
    }

	/**
     * boring ERC20 function to recieve tokens
     */
    function recieve20Token(address token, address sender, uint256 amount) internal returns(bool) {
        require(Geos20(token).allowance(sender, address(this)) >= amount, "Need to approve us for WIZZY to farm");
        require(Geos20(token).transferFrom(sender, address(this), amount), "Need to pay us WIZZY to go farming");
        return true;
    }

    /**
     * boring ERC20 function to get token decimals
     */
	function getTokenDecimals(address token) internal view returns(uint256 decimals){
		decimals = Geos20(token).decimals();
		require(decimals != 0, "GeopolyFarms: Cannot pay with a 0 decimal token");
	}
	// checks if the token is supported to be paid with for geospons
	function isTokenSupported(address token) internal view returns(bool){
		return(_costs[token] != 0);
	}
	// get the cost of the 1 geospin for this token
	function _getCost(address token) internal view returns(uint256 cost){
		if(token == address(this)){
			cost = _costs[address(this)]*priceBasis;
		}else{
			require(isTokenSupported(token), "GeopolyFarms: This token is not supported");
			cost = _costs[token]*(10**getTokenDecimals(token));			
		}
		require(cost != 0, "GeopolyFarms: Cost cannot be zero.");
	}
	// buy spins using any supported token
	function buySpins(uint256 amount, address token) external payable {
		require(geoSpinSales, "GeopolyFarms: Sale of geospins is paused");
		if(token == address(0)){
			require(msg.value >= (_getCost(address(this))*amount), "GeopolyFarms: need to pay cost for geospins in matic");
		}else{
			require(recieve20Token(token, msg.sender, (_getCost(token))*amount), "GeopolyFarms: need to pay cost for geospins in tokens");
		}
		_safeAddSpins(amount, msg.sender);
		emit SpinsPurchased(amount, msg.sender);
	}

	// remove spins called from any geopoly contract
	function removeSpin(address owner, uint256 amount) external isGeopolyContract {
		require(spinBalance(owner) >= amount, "GeopolyFarms: Not enough spins");
		_spins[owner] -= amount;
	}

	// add spins internal function to add the amount to owner address
	function _safeAddSpins(uint256 amount, address owner) internal {
		require(amount != 0, "GeopolyFarms: Cannot add 0 spins");
		_spins[owner] += amount;
	}
	// returns the spin balance of a wallet
	function spinBalance(address wallet) public view returns(uint256){
		return(_spins[wallet]);
	}

	/**
	 * @notice to change the value for the native token, use the address of 
	 * the contract 
	 * @dev sets the supported token address and amount as a cost for 1 geospin
	 */
	function setSupportedToken(address token, uint256 amount) external isAdmin {
		_costs[token] = amount;
	}
	// returns the current farming status 
	function checkFarmStatus() public view returns(bool){
		return(farmingStatus);
	}
	//  returns the NFT category and tier of an NFT
	function _checkNFTProps(uint256 tokenID) internal view returns(uint256 category, uint256 tier){
        string memory _main = GeoPolyNFT(NFT).getMintingString(tokenID);
        (category,tier,,,) = GeoSpeical(geospecial).doAll(_main);
	}

	function getRewards(uint256 tokenID) public view returns(uint256 _reward){
		(uint256 category, uint256 tier) = _checkNFTProps(tokenID);
        if(category == 25){
            category = 10;
        }else if(category == 26){
            category = 20;
        }else{
            category = category;
        }
		uint256 _cat = ((category+1)/2);
        _reward = _cat + (((tier)*125)/100);
		_reward = ((_reward*baseMultiplier)/baseDivisor)+baseOffset;
	}


	function withdrawNative(uint256 amount, address to) external onlyOwner {
		require(address(this).balance >= amount,"GeopolyFarms: Not enough balance");
        require(payable(to).send(amount), "GeopolyFarms: Cannot process withdrawal to this address");
	}

	function withdraw20Tokens(address token, uint256 amount, address to) external onlyOwner {
		require(Geos20(token).balanceOf(address(this)) > amount, "GeopolyFarms: Not enough balance");
		require(Geos20(token).transfer(to, amount));
	}

}