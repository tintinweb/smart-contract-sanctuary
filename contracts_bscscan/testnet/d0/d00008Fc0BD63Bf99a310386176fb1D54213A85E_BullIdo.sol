// SPDX-License-Identifier: MIT

pragma solidity >=0.6.10;
pragma experimental ABIEncoderV2;
import "./SafeERC20.sol";
import "./Ownable.sol";
import "./IERC20.sol";
import "./ReentrancyGuard.sol";
import "./Initializable.sol";
contract BullIdo is Ownable,Initializable{
    using SafeMath for uint256;
    using SafeERC20 for IERC20;
    event _userParticipate(address indexed _user,uint256 _amount,uint256 _participateBlock,bool indexed _fcfs);
    event _userclaim(address indexed _user,uint256 _amount,uint256 indexed _ClaimBlock);
    //target token for offering
    IERC20 offeringToken;
    // rasingToken from user
    IERC20 rasingToken;
    //total token allocation for offering to user
    uint256 totalAllocation;
    // total token purchased by users
    uint256 usedAllocation;
    // time to initial release token
    uint256 releseBlock;
    // block to release remained token part releseBlock+vestingduration 
    uint256 vestingBlock;
    // total number of whitelisted user
    uint256 totalWhitelist;
    // initial offering startBlock
    uint256 startBlock;
    // intial offering endingblock
    uint256 endBlock;
    // Total Offering Token
    uint256 offeringAllocation;
    // time to start offering remained part after endBlock
    uint256 fcfsStartBlock;
    // time to stop fcfs offering have to be before releseBlock
    uint256 fcfsEndBlock;
    // offer remained  allocation if whitelisted wallet dont use 100% of allocation
    bool OfferRemainedAllocation;
    // get user details
    mapping (address => user) User;
    struct user{
        bool whitelist;
        uint256 participationAmount;
        uint256 lastParticipationBlock;
        bool fcFsparticipator;
        uint256 claimDebt;
    }
    // intialize contract initial parameters
    function initialize(
    IERC20 _offeringToken,
    IERC20 _rasingToken,
    uint256 _totalAllocation,
    uint256 _releseBlock,
    uint256 _vestingBlock,
    uint256 _startBlock,
    uint256 _offeringDuration,
    uint256 _offeringAllocation,
    uint256 _fcfsStartBlock,
    uint256 _fcfsDuration,
    bool _OfferRemainedAllocation
    )public initializer returns(bool){
        // check offering token and rasingToken  credit 
        require(address(_offeringToken) != address(0) && address(_rasingToken) != address(0),"BullPad:Zero Address Error");
        // check releaseblock is sooner than vestingBlock
        require(_releseBlock<=_vestingBlock,"BullPad: vesting block have to be after release block");
        //check vestingPercentrage is less than 100
        //check _offeringDuration be more than 0
        require(_offeringDuration>0,"BullPad:Invalid _OFferingDuration Duration");
        // check offeringToken balance be equal or more than _totalAllocation
        require(_offeringToken.balanceOf(address(this))>=_offeringAllocation , "BullPad:insufficent Balance");
        //check fcfs _fcfsDuration be more than 0
        _OfferRemainedAllocation == true?require(_fcfsDuration>0,"BullPad:Invalid _fcfsDuration Duration"):();
        offeringToken = _offeringToken;
        rasingToken = _rasingToken;
        totalAllocation = _totalAllocation;
        releseBlock = _releseBlock;
        vestingBlock = _vestingBlock;
        startBlock = _startBlock;
        endBlock = _startBlock.add(_offeringDuration);
        OfferRemainedAllocation = _OfferRemainedAllocation;
        offeringAllocation = _offeringAllocation;
        fcfsStartBlock = _fcfsStartBlock;
        fcfsEndBlock = _fcfsStartBlock.add(_fcfsDuration);
        return true;
    }
        
    modifier onlyWhitelisted(address _user){
        require(userInfo(_user).whitelist,"BullPad: Only Whitelisted Address");
        _;
    }
    // change users whitelist status to true;
    function whitelistAddress(address[] memory _user)public onlyOwner returns(bool){
        for(uint256 i;i<_user.length;i++){
            if(User[_user[i]].whitelist==false){
            User[_user[i]].whitelist = true;
            totalWhitelist++;
            }
        }
    }
    // change users whitelist status to false
    function removeAddress(address[] memory _user)public onlyOwner returns(bool){
        for(uint256 i;i<_user.length;i++){
            if(User[_user[i]].whitelist==true){
            User[_user[i]].whitelist = false;
            totalWhitelist--;
            }
        }
    }
    function _participate(address _user,uint256 _amount) internal onlyWhitelisted(_user){
        require(_amount>0,"BullPad:Zero Participation Error");
        require(block.number > startBlock && block.number < endBlock,"BullPad:Invalid Ido Time");
        user storage userDetails=User[_user];
        rasingToken.safeTransferFrom(_msgSender(),address(this),_amount);
        //avoid user participate more than share
        whiteListAllocation().sub(userDetails.participationAmount).sub(_amount,"BullPad:Participation Amount Overflow");
        User[_user]=user(userDetails.whitelist,(userDetails.participationAmount).add(_amount),block.number,false,0);
        usedAllocation = usedAllocation.add(_amount);
        emit _userParticipate(_user,_amount,block.number,false);
        
    }
    function _fcfsParticipate(address _user,uint256 _amount) internal{
        require(_amount>0,"BullPad:Zero Participation Error");
        require(OfferRemainedAllocation==true,"BullPad:Fcfs Is Not Planned");
        require(block.number > fcfsStartBlock && block.number < fcfsEndBlock,"BullPad:Invalid Ido Time");
        uint256 remainedAllocation = totalAllocation.sub(usedAllocation);
        uint256 newAllocation;
        user storage userDetails=User[_user];
        // check remainedAllocation if participation amount be more than remained allocation let user to participate remained allocation and set endblock=block.number
         if(remainedAllocation > _amount){
             rasingToken.safeTransferFrom(_msgSender(),address(this),_amount);
             newAllocation = _amount;
             usedAllocation = usedAllocation.add(_amount);
         }
         else{
            rasingToken.safeTransferFrom(_msgSender(),address(this),remainedAllocation);
            newAllocation = remainedAllocation;
            usedAllocation = totalAllocation;
            fcfsEndBlock = block.number;
         }
         User[_user]=user(userDetails.whitelist,userDetails.participationAmount.add(newAllocation),block.number,true,0);
         emit _userParticipate(_user,newAllocation,block.number,true);                     
    }
    function _claimShare(address _user)internal returns(uint256){
        require(block.number> (OfferRemainedAllocation==true ? fcfsEndBlock : endBlock),"BullPad:Claim Only After Ido");
        user storage userDetails = User[_user];
        uint256 ClaimableShare = _userShare(_user);
        userDetails.claimDebt = userDetails.claimDebt.add(ClaimableShare);
        ClaimableShare > 0 ? offeringToken.safeTransfer(_user,ClaimableShare):();
        emit _userclaim(_user,ClaimableShare,block.number);
        return ClaimableShare;
    }
    
    function withdraw(IERC20 _token,address payable _recipient,uint256 _amount,bool native) public onlyOwner {
    require(block.number>(OfferRemainedAllocation==true ? fcfsEndBlock : endBlock),"BullPad:Withdrawal Only After Ido");
       native==false ? _token.safeTransfer(_recipient,_amount) : _recipient.transfer(_amount);
    }
        
      //let owner to change ido time
        function setIdoBlock(uint256 _startBlock,uint256 _endBlock,bool fcfsBlock)public onlyOwner{
        if(fcfsBlock==true){
            fcfsStartBlock = _startBlock;
            fcfsEndBlock = _endBlock;
        }
        else{
            startBlock = _startBlock;
            endBlock = _endBlock;
        }
    }
    
    //let owner to change token addresses
    function setToken(IERC20 _token,bool rasing)public onlyOwner{
        if(rasing==true){
            rasingToken = _token;
        }
        else{
            offeringToken = _token; 
        }
    }
    
    // let owner to set token claim time
    function setReleaseBlock(uint256 _releaseBlock,uint256 _vestingBlock)public onlyOwner{
        releseBlock = _releaseBlock;
  
        vestingBlock = _vestingBlock;
    }
    
    function setFcfs(bool _Fcfs)public onlyOwner{
        OfferRemainedAllocation = _Fcfs;
    }
    
    //let owner to change allocation ->change in price will happend
    function setAllocation(uint256 _allocation,bool _rasing)public onlyOwner{
        if(_rasing == true){
            totalAllocation = _allocation;
        }
        else{
            offeringAllocation = _allocation;
        }
    }
    
    
    //view functions 
    // max token whitelisted wallet can participate;
     function whiteListAllocation() public view returns(uint256){
        return totalAllocation.div(totalWhitelist);
    }
    
    //user token allocation after ido calculation
    function _userShare(address _user)internal view returns(uint256){
        user storage userDetails=User[_user];
        uint256 userAmount=userDetails.participationAmount;
        uint256 userToken=userAmount.mul(offeringAllocation).div(totalAllocation);
        uint256 finalShare=block.number>vestingBlock ? userToken : userToken.div(2);
        return finalShare.sub(userDetails.claimDebt);
    }

     // return user information
    function userInfo(address _user) public view returns(user memory){
     return User[_user];
    }
        // let another contract get ido Information 
    function idoInfo()public view returns(
    IERC20,
    IERC20,
    uint256,
    uint256,
    uint256,
    uint256,
    uint256,
    uint256,
    uint256,
    uint256,
    uint256,
    uint256,
    bool
        ){
        return (
            offeringToken,
            rasingToken,
            totalAllocation,
            usedAllocation,
            releseBlock,
            vestingBlock,
            totalWhitelist,
            startBlock,
            endBlock,
            offeringAllocation,
            fcfsStartBlock,
            fcfsEndBlock,
            OfferRemainedAllocation
            );
    }

}