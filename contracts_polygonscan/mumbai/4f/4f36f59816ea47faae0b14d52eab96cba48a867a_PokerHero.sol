// SPDX-License-Identifier: MIT
pragma experimental ABIEncoderV2;
pragma solidity >=0.8.0;

import "./ERC721Namable.sol";
import "./SafeMath.sol";
import "./IERC1155.sol";
import "./Ownable.sol";
import "./IYieldToken.sol";


contract PokerHero is Ownable, ERC721Namable{
    using SafeMath for uint256;

    uint256[] secondType;
    uint256[] thirdType;

    uint256 constant PRICE500 = 100 ether;
    uint256 constant PRICE9500 = 150 ether;

    uint256 constant PRICEFORCHANGENAME = 50 ether;

    uint256 private stopSale = 1640383156;

    uint256 constant MAX_NFT = 10000;

    IYieldToken yieldToken;
    
    mapping(address => uint256) public balanceFirstType;
    mapping(address => uint256) public balanceSecondType;
    mapping(address => uint256) public balanceThirdType;

    receive() external payable {}
    fallback() external payable {}

    constructor(string memory _name, string memory _symbol) ERC721Namable(_name, _symbol) {
		_setBaseURI("https://BaseUri");

        secondType = [317,420,438,536,742,1040,1224,1450,1511,1527,1690,1965,2232,2397,2867,2923,3514,3699,4159,4435,4558,4673,5044,5446,5858,6038,6478,6511,6674,6733,6819,6841,6981,7053,7435,7449,7513,7608,7657,7831,8044,8215,8567,8739,8803,9297,9316,9378,9588,9627,9723,9876];
        thirdType = [9991,9992,9993,9994,9995,9996,9997,9998,9999,10000];
	}

    function withdraw() public onlyOwner {
        address _this = address(this);
        payable(owner()).transfer(_this.balance);
    }

	function updateURI(string memory _newURI) public onlyOwner {
		_setBaseURI(_newURI);
	}

    function setYieldToken(address _yieldToken) public onlyOwner {
        yieldToken = IYieldToken(_yieldToken);
    }

    function changeDateOfStopSale(uint256 _newDate) public onlyOwner{
        stopSale = _newDate;
    }


    function getBalance() public view returns(uint256) {
        address _self = address(this);
        uint256 _balance = _self.balance;
        return _balance;
    }

    function mint(uint256 _id) public payable {
        require(MAX_NFT != totalSupply(), "NFT are over! Sorry :(");
        require(stopSale >= block.timestamp, "Mint time is over!");
        require(balanceOf(msg.sender) + 1 <= 10, "More than 10 NFTs");

        if(totalSupply() <= 500){
            require(PRICE500 == msg.value, "Value isn't correct");
        }
        else{
            require(PRICE9500 == msg.value, "Value isn't correct");
        }

        _mint(msg.sender, _id);  

        if(isSecondType(_id)) {
            yieldToken.updateRewardOnMint(msg.sender, 2);
            balanceSecondType[msg.sender]++;
        }else if(isThirdType(_id)) {
            yieldToken.updateRewardOnMint(msg.sender, 3);
            balanceThirdType[msg.sender]++;
        }else{
            yieldToken.updateRewardOnMint(msg.sender, 1);
            balanceFirstType[msg.sender]++;
        }        
    }

    function changeNameOfNFT(uint tokenId, string memory newName) public payable{
        require(PRICEFORCHANGENAME == msg.value, "Value isn't correct");
        changeName(tokenId,newName);
    }

    function mintRestCollection(uint256[] memory _ids) public onlyOwner{
        for(uint i=0; i<_ids.length; i++) {
            _mint(msg.sender, _ids[i]);
        }
    }

    function mintBatch(uint256[] memory _ids) public payable{
        require(MAX_NFT != totalSupply(), "NFT are over! Sorry :(");
        require(stopSale >= block.timestamp, "Mint time is over!");
        require(balanceOf(msg.sender) + _ids.length <= 10, "More than 10 NFTs");

        uint256 _count = (totalSupply() + _ids.length) <= MAX_NFT ? _ids.length : MAX_NFT - totalSupply();

        if(totalSupply() <= 500){
            require(PRICE500 * _count == msg.value, "Value isn't correct");
        }
        else{
            require(PRICE9500 * _count== msg.value, "Value isn't correct");
        }

        uint256 _fType;
        uint256 _sType;
        uint256 _tType;

        for(uint i=0; i<_count; i++) {
            _mint(msg.sender, _ids[i]);

            if(isSecondType(_ids[i])) {
                _sType++;
            }else if(isThirdType(_ids[i])) {
                _tType++;
            }else{
                _fType++;
            }
        }

        yieldToken.updateRewardOnMint(msg.sender, _fType+_sType+_tType);        
        balanceSecondType[msg.sender]+=_sType;
        balanceThirdType[msg.sender]+=_tType;
        balanceFirstType[msg.sender]+=_fType;
    }

    function isSecondType(uint256 _id) internal view returns(bool) {
        for(uint i=0; i<secondType.length; i++) {
            if(secondType[i] == _id) {
                return true;
            }
        }
        return false;
    }

    function isThirdType(uint256 _id) internal pure returns(bool) {
        return _id >= 9991;
    }

    function getReward() external {
		yieldToken.updateReward(msg.sender, address(0));
		yieldToken.getReward(msg.sender);
	}

    function transferFrom(address _from, address _to, uint256 _tokenId) public override {
        yieldToken.updateReward(_from, _to);
		
        if(isSecondType(_tokenId)){
		    balanceSecondType[_from]--;
            balanceSecondType[_to]++;
        }else if(isThirdType(_tokenId)){
            balanceThirdType[_from]--;
		    balanceThirdType[_to]++;
        }else{
            balanceFirstType[_from]--;
            balanceFirstType[_to]++;
        }
		
		super.transferFrom(_from, _to, _tokenId);
    }

    function safeTransferFrom(address _from, address _to, uint256 _tokenId) public override {
        yieldToken.updateReward(_from, _to);
		
        if(isSecondType(_tokenId)){
		    balanceSecondType[_from]--;
            balanceSecondType[_to]++;
        }else if(isThirdType(_tokenId)){
            balanceThirdType[_from]--;
		    balanceThirdType[_to]++;
        }else{
            balanceFirstType[_from]--;
            balanceFirstType[_to]++;
        }
		
		super.safeTransferFrom(_from, _to, _tokenId);
    }

    function safeTransferFrom(address _from, address _to, uint256 _tokenId, bytes memory _data) public override {
        yieldToken.updateReward(_from, _to);
		
        if(isSecondType(_tokenId)){
		    balanceSecondType[_from]--;
            balanceSecondType[_to]++;
        }else if(isThirdType(_tokenId)){
            balanceThirdType[_from]--;
		    balanceThirdType[_to]++;
        }else{
            balanceFirstType[_from]--;
            balanceFirstType[_to]++;
        }
		
		super.safeTransferFrom(_from, _to, _tokenId, _data);
    }
}