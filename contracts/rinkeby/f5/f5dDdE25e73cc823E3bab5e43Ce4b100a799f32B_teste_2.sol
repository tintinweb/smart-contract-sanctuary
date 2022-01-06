// SPDX-License-Identifier: MIT LICENSE
pragma solidity ^0.8.4;

import "./Ownable.sol";
import "./IERC721Receiver.sol";
import "./teste_1.sol";
import "./teste_3.sol";

contract teste_2 is IERC721Receiver,Ownable{

    struct stakedInfo{
        address owner;
        uint256 tokenId;
        uint256 lastUpdate;
        bool exists;
    }
    //1000 Mellows per day
    uint256 constant public MELLOW_RATE = 1000 ether;
    uint256 public constant minimumToUnstake = 2 minutes;
    uint256 public totalMalloStaked;

    mapping(uint256 => stakedInfo) firepit;

    bool public staking = false;
    // Metamallow NFT contract reference
    teste_1 teste_1Contract;
    teste_3 teste_3Token;

    event tokenStaked(address _owner, uint256 _tokenId, uint256 _lastUpdate);
    event claimedLove(uint256 _tokenId, uint256 _loveEarned, bool _unstake);
    constructor (
        address _teste_1Address
        //address _melloAddress
    ){
        //loveToken = MELLO(_melloAddress);
        teste_1Contract = teste_1(_teste_1Address);
    }
    function setTeste_3Address(address _teste_3TokenAddress) public onlyOwner{
        teste_3Token = teste_3(_teste_3TokenAddress);
    }
    function stakingTokens(uint16[] calldata _tokenIds) public{
        require(staking,"Staking not available yet");
        for (uint i = 0; i < _tokenIds.length; i++) {
            require (!firepit[_tokenIds[i]].exists, 'Already in stake');
            require(_msgSender() == teste_1Contract.ownerOf(_tokenIds[i]),"Not the owner of this token");
            teste_1Contract.transferFrom(_msgSender(), address(this),_tokenIds[i]);
            uint256 timestamp = uint80(block.timestamp);
            firepit[_tokenIds[i]] = stakedInfo({
                owner: _msgSender(),
                tokenId: _tokenIds[i],
                lastUpdate: timestamp,
                exists: true
            });
            totalMalloStaked += 1;
            emit tokenStaked(_msgSender(), _tokenIds[i], timestamp);
        } 
    }
    //[1,2,3] , [true,false,false]
    function clamingTokens(uint16[] calldata _tokenIds, bool[] calldata _unstake) public{
        require(staking,"Staking not available yet.");
        require(_tokenIds.length == _unstake.length, "Token Ids must have the same lenght as unstake");
        uint256 reward = 0;
        for (uint i = 0; i < _tokenIds.length; i++) {
            require(firepit[_tokenIds[i]].exists,"Not in stake");
            require(firepit[_tokenIds[i]].owner == msg.sender, "Not the user which has staked this token");
            //require(msg.sender == metamallowContract.ownerOf(_tokenId),"Not the owner of the NFT");
            reward += MELLOW_RATE * (block.timestamp - firepit[_tokenIds[i]].lastUpdate) / 1 minutes;
            if(_unstake[i]){
                if((block.timestamp - firepit[_tokenIds[i]].lastUpdate) >= minimumToUnstake){
                    teste_1Contract.safeTransferFrom(address(this), msg.sender, _tokenIds[i], ""); // Send back the NFT
                    //Update the list
                    delete firepit[_tokenIds[i]];
                    totalMalloStaked -= 1;
                }
            }
            else{
                firepit[_tokenIds[i]] = stakedInfo({
                    owner: _msgSender(),
                    tokenId: _tokenIds[i],
                    lastUpdate: uint80(block.timestamp),
                    exists: true
                });    
            }
            emit claimedLove(_tokenIds[i], reward, _unstake[i]);
        }
        teste_3Token.mint(msg.sender,reward);
    }
    function calculateReward(uint256 _tokenId) public view returns (uint256){
        return (MELLOW_RATE * (block.timestamp - firepit[_tokenId].lastUpdate) / 1 minutes);
    }
    function viewfirepit (uint256 _tokenId) public view returns (stakedInfo memory){
        return firepit[_tokenId];
    }
    /* function inStake(address _wallet) public view returns (bool) {
        require(staking,"Staking not available yet");
        for (uint i = 0; i < firepit.length; i++) {
            if (firepit[i].owner == _wallet) {
                return true;
            }
        }
        return false;
    } */
    /* function getIndex(address _wallet) private view returns (uint){
        for(uint256 i=0; i< firepit.length ; i++){
            if(_wallet == firepit[i].owner){
                return i;
           }
       }
       return 0;
    } */
    /* function updateList(address _wallet) private{
        require(inStake(_wallet),"Wallet not in stake");
        for(uint256 i=getIndex(_wallet); i< firepit.length -1; i++){
            firepit[i] = firepit[i+1];
            //list[i] = 1;
        }
        firepit.pop();
    } */
    function setStake(bool _state) public onlyOwner {
		staking = _state;
	}
    function viewStakingStage() external view returns(bool){
		return staking;
	}
    function onERC721Received(
        address,
        address from,
        uint256,
        bytes calldata
    ) external pure override returns (bytes4) {
      require(from == address(0x0), "Must use staking function to send tokens to the Fire Pit");
      return IERC721Receiver.onERC721Received.selector;
    }
}