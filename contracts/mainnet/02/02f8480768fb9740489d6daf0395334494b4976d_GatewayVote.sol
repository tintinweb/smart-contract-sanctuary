pragma solidity ^0.4.24;


interface App 
{
    function mint(address receiver, uint64 wad) external returns (bool);
    function changeGatewayAddr(address newer) external returns (bool);
}

contract GatewayVote 
{
    
    struct Vote 
    {
        bool done;
        uint poll;
        mapping(uint256 => uint8) voters;
    }
    
    struct AppInfo
    {
        uint32 chainCode;
        uint32 tokenCode;
        uint256 app;
    }


    // FIELDS
    bool    public mStopped;
    uint32  public mMaxAppCode;
    uint32  public mMaxChainCode;
    uint256 public mNumVoters;
    
    mapping(uint256 => uint8) mVoters;
    mapping(uint256 => Vote) mVotesStore;
    
    mapping(uint256 => uint32) mAppToCode;
    mapping(uint32 => AppInfo) mCodeToAppInfo;
    
    mapping(string => uint32) mChainToCode;
    mapping(uint32 => string) mCodeToChain;
    

    // EVENTS
    event Stopped(uint256 indexed operation);
    event Started(uint256 indexed operation);
    
    event Confirmation(address voter, uint256 indexed operation);
    event OperationDone(address voter, uint256 indexed operation);
    event Revoke(address revoker, uint256 indexed operation);
    
    event VoterChanged(address oldVoter, address newVoter, uint256 indexed operation);
    event VoterAdded(address newVoter, uint256 indexed operation);
    event VoterRemoved(address oldVoter, uint256 indexed operation);
    
    event ChainAdded(string chain, uint256 indexed operation);
    
    event AppAdded(address app, uint32 chain, uint32 token, uint256 indexed operation);
    event AppRemoved(uint32 code, uint256 indexed operation);
    
    event MintByGateway(uint32 appCode, address receiver, uint64 wad, uint256 indexed operation);
    event BurnForGateway(uint32 appCode, address from, string dstDescribe, uint64 wad, uint64 fee);

    event GatewayAddrChanged(uint32 appCode, address newer, uint256 indexed operation);

    // METHODS

    constructor(address[] voters) public 
    {
        mNumVoters = voters.length;
        for (uint i = 0; i < voters.length; ++i)
        {
            mVoters[uint(voters[i])] = 1;
        }
    }
    
    function isVoter(address voter) public view returns (bool) 
    {
        return mVoters[uint(voter)] == 1;
    }
    
    function isApper(address app) public view returns (bool) 
    {
        return mAppToCode[uint(app)] > 0;
    }
    
    function isAppCode(uint32 code) public view returns (bool) 
    {
        return mAppToCode[uint256(mCodeToAppInfo[code].app)] == code;
    }
    
    function getAppAddress(uint32 code) public view returns (address) 
    {
        return address(mCodeToAppInfo[code].app);
    }
    
    function getAppChainCode(uint32 code) public view returns (uint32) 
    {
        return mCodeToAppInfo[code].chainCode;
    }
    
    function getAppTokenCode(uint32 code) public view returns (uint32)
    {
        return mCodeToAppInfo[code].tokenCode;
    }
    
    function getAppInfo(uint32 code) public view returns (address, uint32, uint32)
    {
        return (address(mCodeToAppInfo[code].app), mCodeToAppInfo[code].chainCode, mCodeToAppInfo[code].tokenCode);
    }
    
    function getAppCode(address app) public view returns (uint32) 
    {
        return mAppToCode[uint256(app)];
    }
    
    function isCaller(address addr) public view returns (bool) 
    {
        return isVoter(addr) || isApper(addr);
    }
    
    function isChain(string chain) public view returns (bool) 
    {
        return mChainToCode[chain] > 0;
    }
    
    function isChainCode(uint32 code) public view returns (bool)
    {
        return mChainToCode[mCodeToChain[code]] == code;
    }
    
    function getChainName(uint32 code) public view returns (string) 
    {
        return mCodeToChain[code];
    }
    
    function getChainCode(string chain) public view returns (uint32) 
    {
        return mChainToCode[chain];
    }
    
    function hasConfirmed(uint256 operation, address voter) public constant returns (bool) 
    {
        if (mVotesStore[operation].voters[uint(voter)] == 1) 
        {
            return true;
        } 
        else 
        {
            return false;
        }
    }
    
    function major(uint total) internal pure returns (uint r) 
    {
        r = (total * 2 + 1);
        return r%3==0 ? r/3 : r/3+1;
    }

    function confirmation(uint256 operation) internal returns (bool) 
    {
        Vote storage vote = mVotesStore[operation];
        
        if (vote.done) return;
        
        if (vote.voters[uint(tx.origin)] == 0) 
        {
            vote.voters[uint(tx.origin)] = 1;
            vote.poll++;
            emit Confirmation(tx.origin, operation);
        }
        
        //check if poll is enough to go ahead.
        if (vote.poll >= major(mNumVoters)) 
        {
            vote.done = true;
            emit OperationDone(tx.origin, operation);
            return true;
        }
    }
    
    function stop(string proposal) external 
    {
        // the origin tranx sender should be a voter
        // contract should be running
        require(isVoter(tx.origin) && !mStopped);
        
        // wait for voters until poll >= major
        if(!confirmation(uint256(keccak256(msg.data)))) return;
        
        // change state
        mStopped = true;
        
        // log output
        emit Stopped(uint(keccak256(msg.data)));
    }
    
    function start(string proposal) external 
    {
        
        // the origin tranx sender should be a voter
        // contract should be stopped
        require(isVoter(tx.origin) && mStopped);
        
        if(!confirmation(uint256(keccak256(msg.data)))) return;
        
        mStopped = false;
        
        emit Started(uint(keccak256(msg.data)));
    }
    
    function revoke(uint256 operation) external 
    {
        
        require(isVoter(tx.origin) && !mStopped);
        
        Vote storage vote = mVotesStore[operation];
        
        // the vote for this operation should not be done
        // the origin tranx sender should have voted to this operation
        require(!vote.done && (vote.voters[uint(tx.origin)] ==  1));
        
        vote.poll--;
        delete vote.voters[uint(tx.origin)];
        
        emit Revoke(tx.origin, operation);
    }
    
    function changeVoter(address older, address newer, string proposal) external 
    {
        
        require(isVoter(tx.origin) && !mStopped && isVoter(older) && !isVoter(newer));
        
        if(!confirmation(uint256(keccak256(msg.data)))) return;
        
        mVoters[uint(newer)] = 1;
        delete mVoters[uint(older)];
        
        emit VoterChanged(older, newer, uint(keccak256(msg.data)));
    }
    
    function addVoter(address newer, string proposal) external 
    {
        
        require(isVoter(tx.origin) && !mStopped && !isVoter(newer));
        
        if(!confirmation(uint256(keccak256(msg.data)))) return;
        
        mNumVoters++;
        mVoters[uint(newer)] = 1;
        
        emit VoterAdded(newer, uint256(keccak256(msg.data)));
    }
    
    function removeVoter(address older, string proposal) external 
    {
        
        require(isVoter(tx.origin) && !mStopped && isVoter(older));
        
        if(!confirmation(uint256(keccak256(msg.data)))) return;
        
        mNumVoters--;
        delete mVoters[uint(older)];
        
        emit VoterRemoved(older, uint256(keccak256(msg.data)));
    }
    
    function addChain(string chain, string proposal) external 
    {
        require(isVoter(tx.origin) && !mStopped && !isChain(chain));
        
        if(!confirmation(uint256(keccak256(msg.data)))) return;
        
        mMaxChainCode++;
        mChainToCode[chain] = mMaxChainCode;
        mCodeToChain[mMaxChainCode] = chain;
        
        emit ChainAdded(chain, uint256(keccak256(msg.data)));
    }
    
    function addApp(address app, uint32 chain, uint32 token, string proposal) external 
    {
        require(isVoter(tx.origin) && !mStopped && !isApper(app) && isChainCode(chain));
        
        if(!confirmation(uint256(keccak256(msg.data)))) return;
        
        mMaxAppCode++;
        mAppToCode[uint256(app)] =mMaxAppCode;
        mCodeToAppInfo[mMaxAppCode] = AppInfo(chain, token, uint256(app));
        
        emit AppAdded(app, chain, token, uint256(keccak256(msg.data)));
    }
    
    function removeApp(uint32 code, string proposal) external 
    {
        require(isVoter(tx.origin) && !mStopped && isAppCode(code));
        
        if(!confirmation(uint256(keccak256(msg.data)))) return;
    
        delete mAppToCode[uint256(mCodeToAppInfo[code].app)];
        
        emit AppRemoved(code, uint256(keccak256(msg.data)));
    }
    
    function mintByGateway(uint32 appCode, uint64 wad, address receiver, string proposal) external 
    {
        require(isVoter(tx.origin) && !mStopped && isAppCode(appCode));
        
        if(!confirmation(uint256(keccak256(msg.data)))) return;
        
        if (App(address(mCodeToAppInfo[appCode].app)).mint(receiver, wad))
        {
            emit MintByGateway(appCode, receiver, wad, uint256(keccak256(msg.data)));
        }
    }
    
    function changeGatewayAddr(uint32 appCode, address newer, string proposal) external 
    {
        require(isVoter(tx.origin) && !mStopped && isAppCode(appCode));
        
        if(!confirmation(uint256(keccak256(msg.data)))) return;
        
        if(App(address(mCodeToAppInfo[appCode].app)).changeGatewayAddr(newer)) 
        {
            emit GatewayAddrChanged(appCode, newer, uint256(keccak256(msg.data)));
        }
    }
    
    function burnForGateway(address from, string dstDescribe, uint64 wad, uint64 fee) external 
    {
        require(isApper(msg.sender));
        emit BurnForGateway(mAppToCode[uint256(msg.sender)], from, dstDescribe, wad, fee);
    }
}