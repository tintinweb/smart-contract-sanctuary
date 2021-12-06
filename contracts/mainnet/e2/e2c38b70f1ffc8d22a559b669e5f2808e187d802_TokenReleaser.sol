// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// We'll actually use ERC777, but any IERC20 instance (including ERC777)
// is supported.
import 'openzeppelin-solidity/contracts/token/ERC20/IERC20.sol';


contract TokenReleaser {


    event TokensBook(address beneficiary , uint256 tokenAmount, uint8 releaseType); 

    struct ReleaseType
     {  uint256 tokenLockTime             ; // lockup time after the release time starts.

        uint256 tokenReleaseDuration      ; // vesting time during which the token will be gradually released.
                                            // if 0, it means everything available at once. 

        uint256 immediateAccessTimeWindow ; // When the release time starts, the beneficiary will have immediate access to 
     }                                      // all the tokens to be released to him during the his `immediateAccessTimeWindow`.

    struct Beneficiary
     {  uint8   releaseType           ;     // public sale, seed round ...
        uint256 tokensAlreadyReleased ;
        uint256 tokenBookedAmount     ;
     }




    uint16 constant SEED_ROUND                      = 0;
    uint16 constant PRIVATE_ROUND                   = 1;
    uint16 constant STRATEGIC_ROUND                 = 2;
    uint16 constant PUBLIC_SALE                     = 3;
    uint16 constant COMPANY_RESERVE                 = 4;
    uint16 constant TEAM_AND_ADVISORS               = 5;
    uint16 constant STRATEGIC_PARTNERS              = 6;
    uint16 constant FOUNDERS_AND_EARLY_CONTRIBUTORS = 7;
    uint16 constant MINING_RESERVE                  = 8;

    uint16 constant MAX_RELEASE_TYPE                = 9;    

    ReleaseType[MAX_RELEASE_TYPE]   public tokenomic;

    uint256                         public avaliableTokensToRelease;
    IERC20                          public tokenContract;
    mapping(address => Beneficiary) public beneficiaries;
    uint256                         public releaseStartTime;
    
    function setTokenomics(uint256 avaliableTokens) private{

        // NOTICE: we take a month to be equivalent to 30 days, regardless of actual calendar months.
        // In particular, 12 month would not sum up a whole year, but 360 days.


        tokenomic[ SEED_ROUND                     ] = ReleaseType
         ({ tokenLockTime             :  0 * 30 days
          , tokenReleaseDuration      : 24 * 30 days 
          , immediateAccessTimeWindow :  1 * 30 days
          }
         );

        tokenomic[ PRIVATE_ROUND                  ] = ReleaseType
         ({ tokenLockTime             :  0 * 30 days
          , tokenReleaseDuration      : 12 * 30 days
          , immediateAccessTimeWindow :  1 * 30 days
          }
         );

        tokenomic[ STRATEGIC_ROUND                ] = ReleaseType
         ({ tokenLockTime             :  0 * 30 days
          , tokenReleaseDuration      : 12 * 30 days
          , immediateAccessTimeWindow :  1 * 30 days
          }
         );

        tokenomic[ PUBLIC_SALE                    ] = ReleaseType
         ({ tokenLockTime             :  0 * 30 days
          , tokenReleaseDuration      :  0 * 30 days
          , immediateAccessTimeWindow :  0 * 30 days 
          } // as `tokenReleaseDuration == 0` everything is available as soon as the release time starts. 
         );

        tokenomic[ COMPANY_RESERVE                ] = ReleaseType
         ({ tokenLockTime             :  0 * 30 days
          , tokenReleaseDuration      : 36 * 30 days
          , immediateAccessTimeWindow :  1 * 30 days
          }
         );

        tokenomic[ TEAM_AND_ADVISORS              ] = ReleaseType
         ({ tokenLockTime             : 12 * 30 days
          , tokenReleaseDuration      : 36 * 30 days
          , immediateAccessTimeWindow :  0 * 30 days
          }
         );

        tokenomic[ STRATEGIC_PARTNERS             ] = ReleaseType
         ({ tokenLockTime             : 12 * 30 days
          , tokenReleaseDuration      : 36 * 30 days
          , immediateAccessTimeWindow :  0 * 30 days
          }
         );

        tokenomic[ FOUNDERS_AND_EARLY_CONTRIBUTORS] = ReleaseType
         ({ tokenLockTime             : 12 * 30 days
          , tokenReleaseDuration      : 48 * 30 days
          , immediateAccessTimeWindow :  0 * 30 days
          }
         );

        tokenomic[ MINING_RESERVE                 ] = ReleaseType
         ({ tokenLockTime             :  6 * 30 days
          , tokenReleaseDuration      : 60 * 30 days
          , immediateAccessTimeWindow :  0 * 30 days
          }
         );

        avaliableTokensToRelease = avaliableTokens;
        
        releaseStartTime = 0;
    }
    
    
    //////////////////////////////////////////////////////////////////////////////////////////
    
    function releaseToken() external{
        
        require( releaseStartTime > 0
               , 'Release time has not started yet'
               )
        ;

        Beneficiary memory beneficiary = beneficiaries[msg.sender];
        
        require( beneficiary.tokenBookedAmount != 0
               , 'Address doesnt belong to a beneficiary set by an admin.'
               )
        ;


        ReleaseType memory releaseType    = tokenomic[beneficiary.releaseType];
        
        // Date the tokens locktime finish for the beneficiary. 
        uint256 startTime = releaseType.tokenLockTime + releaseStartTime;
        
        // After the locktime has finished, there's a time window defined as `tokenReleaseDuration`. 
        // `timeCompleted` is how much of that time window has been completed.
        // A beneficiary can only release a fraction of his token proportional to how much of this time window
        // has been completed (or the totality of them if it is completed).
        uint256 timeCompleted  = 0;
        uint256 unlockedTokens = 0;

        if (block.timestamp >= startTime){
            timeCompleted = block.timestamp - startTime;

            // Time completed is the maximum between the time it has passed since start, and 
            // the immediateAccessTimeWindow, capped to a max of tokenReleaseDuration.
            if (timeCompleted < releaseType.immediateAccessTimeWindow){
                timeCompleted = releaseType.immediateAccessTimeWindow;
            }
        
            if (timeCompleted >= releaseType.tokenReleaseDuration){
                timeCompleted = releaseType.tokenReleaseDuration;
            }

            // `tokenReleaseDuration == 0` means everything is available right after the release lock time
            if (releaseType.tokenReleaseDuration == 0){
                unlockedTokens = beneficiary.tokenBookedAmount;
            } else {
                unlockedTokens = (timeCompleted * beneficiary.tokenBookedAmount) / releaseType.tokenReleaseDuration;
            }
        }

        uint256 toRelease      =  unlockedTokens - beneficiary.tokensAlreadyReleased;
        
        beneficiaries[msg.sender].tokensAlreadyReleased += toRelease;
        
        tokenContract.transfer( msg.sender, toRelease );
        
    }
    
    //////////////////////////////////////////////////////////////////////////////////////////
    address public adminA; // active admin
    address public adminB; // backup admin
    address public adminT; // temporary admin, only used during key rotation for one of the other admins.
    event NewAdminA(address adminA );
    event NewAdminB(address adminB );
    event NewAdminT(address adminT );
    
    modifier adminOnly(){
        require( (msg.sender == adminA) || (msg.sender == adminB) || (msg.sender == adminT) 
               , 'Only admins allowed'
               )
        ;
        _;
    }

    function changeAdminA(address newAdminA) external adminOnly{
        if (adminA != newAdminA){
           emit NewAdminA(newAdminA);
        }
        adminA = newAdminA;
    }

    function changeAdminB(address newAdminB) external adminOnly{
        if (adminB != newAdminB){
           emit NewAdminB(newAdminB);
        }
        adminB = newAdminB;
    }

    function changeAdminT(address newAdminT) external adminOnly{
        if (adminT != newAdminT){
           emit NewAdminB(newAdminT);
        }
        adminT = newAdminT;
    }



    function bookTokensFor( address beneficiary , uint256 tokenAmount, uint8 releaseType ) external adminOnly{
        require( avaliableTokensToRelease >= tokenAmount 
               , 'Not enough token to book'
               )
        ;
        require( beneficiaries[beneficiary].tokenBookedAmount == 0
               , 'Beneficiaries can only be set once'
               )
        ;
        require( releaseType < MAX_RELEASE_TYPE
               , 'Invalid release schedule'
               )
        ;
        require( tokenAmount > 0
               , 'More than 0 token needs to be booked to set a beneficiary'
               )
        ;
        avaliableTokensToRelease -= tokenAmount;
        
        emit TokensBook(beneficiary, tokenAmount, releaseType);
        beneficiaries[beneficiary] = Beneficiary(releaseType,0,tokenAmount);

    }

    event ReleaseTimeStarted();
    

    function startReleaseTime() external adminOnly{
        require( releaseStartTime == 0
               , 'Release time has already started'
               )
        ;
        releaseStartTime = block.timestamp;
        emit ReleaseTimeStarted();
    }

    //////////////////////////////////////////////////////////////////////////////////////////
    
    constructor(address _adminA, address _adminB, IERC20 _contract, uint256 avaliableTokens){
        tokenContract  = _contract;
        adminA         = _adminA;
        adminB         = _adminB;
        setTokenomics(avaliableTokens);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

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
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

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