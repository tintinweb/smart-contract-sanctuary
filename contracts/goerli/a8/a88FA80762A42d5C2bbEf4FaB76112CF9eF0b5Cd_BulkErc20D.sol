// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import './TokenReleaser.sol';


contract BulkErc20D {
    

    modifier adminOnly(){
        require(    (msg.sender == 0xE147f1Ae58466A64Ca13Af6534FC1651ecd0af43) 
                 || (msg.sender == 0x3C159347b33cABabdb6980081f9408759833129b) 
                 || (msg.sender == 0x124250874CE2014e9E2485de47e0252ADF617679) 
               , 'Only admins allowed'
               )
        ;
        _;
    }


    function erc20_transfer_bulk
             ( address[] calldata destinies
             , uint128[] calldata amounts
             ) external adminOnly {
    
        IERC20  tokenContract = IERC20(0x505B5eDa5E25a67E1c24A2BF1a527Ed9eb88Bf04);

        for (uint i=0; i < destinies.length; i++) {
            tokenContract.transfer(destinies[i], amounts[i]);
        }
    
    }

    function book_token_bulk
              ( address[] calldata beneficiaries
              , uint128[] calldata amounts
              , TokenReleaser.ReleaseType releaseSchedule
              ) external adminOnly {

                                                     
        TokenReleaser  tokenContract = TokenReleaser(0x13Fe7160858F2A16b8e4429DFf26c8a3A4b12b1B);

        for (uint i=0; i < beneficiaries.length; i++) {
            tokenContract.bookTokensFor( beneficiaries[i] , amounts[i], releaseSchedule);
        }
    }


    function destroy() external adminOnly{
        selfdestruct(payable(msg.sender));
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// We'll actually use ERC777, but any IERC20 instance (including ERC777)
// is supported.
import 'openzeppelin-solidity/contracts/token/ERC20/IERC20.sol';


contract TokenReleaser {



    /////////////////////////////////////////////////////////////////////////////////////////////////////
    // This smart contract is divided into 3 parts: 
    //
    // - The first part defines the different types of releases (i.e token release for seed round investor,
    //   token release for team and advisor ...etc). Here we define the `ReleaseType` and `ReleaseSchedule`
    //   types, and the function `setTokenomics` which associate to each ReleaseType its associated 
    //   `ReleaseSchedule`. The association between the type of release and its schedule is what we call
    //   the `tokenomic`. Notice `setTokenomics` is called only once, therefore `tokenomic` behaves like
    //   a constant (unfortunately, due to solidity limitations it couldn't get declared as such).
    //
    // - Second part defines the `Beneficiary`, which represent an user (or more generally an address),
    //   that got some tokens booked; and the external function `releaseToken`. A beneficiary will call
    //   `releaseToken` to receive tokens, which will be sent according to the Beneficiary's release
    //   schedule type. Notice `releaseToken` is the only public function a non-admin user can call. 
    //
    // - The third part defines the admins, and the action they control. Each of these actions
    //   is represented by a function and an Event. For security and simplicity reason, we've decide
    //   to keep a fixed max number of admins, 3 of them specifically (though by default we only enable 2 
    //   of them). At any time, any admin can modify the list of admins. 
    //
    // Types, variables and events are defined right before they are mentioned on code. 

    IERC20  public tokenContract;
    
    constructor(address _adminA, address _adminB, IERC20 _contract, uint256 avaliableTokens){
        tokenContract  = _contract;
        adminA         = _adminA;
        adminB         = _adminB;
        setTokenomics(avaliableTokens);
    }



    //////////////////////////////////////////////////////////////////////////////////////////////////////
    // First part:


    enum ReleaseType
      { SEED_ROUND
      , PRIVATE_ROUND
      , STRATEGIC_ROUND
      , PUBLIC_SALE
      , COMPANY_RESERVE
      , TEAM_AND_ADVISORS
      , STRATEGIC_PARTNERS
      , FOUNDERS_AND_EARLY_CONTRIBUTORS
      , MINING_RESERVE
      }

    // Information about how an specific ReleaseType will be scheduled.
    struct ReleaseSchedule
     {  uint256 tokenLockTime             ; // lockup time after the release time starts.

        uint256 tokenReleaseDuration      ; // vesting time during which the token will be gradually released.
                                            // if 0, it means everything available at once. 

        uint256 immediateAccessTimeWindow ; // When the release time starts, the beneficiary will have immediate access to 
     }                                      // all the tokens to be released to him during the his `immediateAccessTimeWindow`.


    mapping(ReleaseType => ReleaseSchedule) public tokenomic;
    uint256 public avaliableTokensToRelease;
    

    // Defines the total amount of tokens available to get release, and how the schedule
    // for each type of release will be. 
    function setTokenomics(uint256 avaliableTokens) private{

        // NOTICE: we take a month to be equivalent to 30 days, regardless of actual calendar months.
        // In particular, 12 month would not sum up a whole year, but 360 days.

        tokenomic[ ReleaseType.SEED_ROUND                     ] = ReleaseSchedule
         ({ tokenLockTime             :  0 * 30 days
          , tokenReleaseDuration      : 24 * 30 days 
          , immediateAccessTimeWindow :  1 * 30 days
          }
         );

        tokenomic[ ReleaseType.PRIVATE_ROUND                  ] = ReleaseSchedule
         ({ tokenLockTime             :  0 * 30 days
          , tokenReleaseDuration      : 12 * 30 days
          , immediateAccessTimeWindow :  1 * 30 days
          }
         );

        tokenomic[ ReleaseType.STRATEGIC_ROUND                ] = ReleaseSchedule
         ({ tokenLockTime             :  0 * 30 days
          , tokenReleaseDuration      : 12 * 30 days
          , immediateAccessTimeWindow :  1 * 30 days
          }
         );

        tokenomic[ ReleaseType.PUBLIC_SALE                    ] = ReleaseSchedule
         ({ tokenLockTime             :  0 * 30 days
          , tokenReleaseDuration      :  0 * 30 days
          , immediateAccessTimeWindow :  0 * 30 days 
          } // as `tokenReleaseDuration == 0` everything is available as soon as the release time starts. 
         );

        tokenomic[ ReleaseType.COMPANY_RESERVE                ] = ReleaseSchedule
         ({ tokenLockTime             :  0 * 30 days
          , tokenReleaseDuration      : 36 * 30 days
          , immediateAccessTimeWindow :  1 * 30 days
          }
         );

        tokenomic[ ReleaseType.TEAM_AND_ADVISORS              ] = ReleaseSchedule
         ({ tokenLockTime             : 12 * 30 days
          , tokenReleaseDuration      : 36 * 30 days
          , immediateAccessTimeWindow :  0 * 30 days
          }
         );

        tokenomic[ ReleaseType.STRATEGIC_PARTNERS             ] = ReleaseSchedule
         ({ tokenLockTime             : 12 * 30 days
          , tokenReleaseDuration      : 36 * 30 days
          , immediateAccessTimeWindow :  0 * 30 days
          }
         );

        tokenomic[ ReleaseType.FOUNDERS_AND_EARLY_CONTRIBUTORS] = ReleaseSchedule
         ({ tokenLockTime             : 12 * 30 days
          , tokenReleaseDuration      : 48 * 30 days
          , immediateAccessTimeWindow :  0 * 30 days
          }
         );

        tokenomic[ ReleaseType.MINING_RESERVE                 ] = ReleaseSchedule
         ({ tokenLockTime             :  6 * 30 days
          , tokenReleaseDuration      : 60 * 30 days
          , immediateAccessTimeWindow :  0 * 30 days
          }
         );

        avaliableTokensToRelease = avaliableTokens;
    }
    
    
    //////////////////////////////////////////////////////////////////////////////////////////
    // Second Part:

    struct Beneficiary
     {  ReleaseType releaseSchedule       ;     // public sale, seed round ...
        uint256     tokensAlreadyReleased ;
        uint256     tokenBookedAmount     ;
     }

    uint256 public releaseStartTime;
    mapping(address => Beneficiary) public beneficiaries;

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


        ReleaseSchedule memory releaseSchedule    = tokenomic[beneficiary.releaseSchedule];
        
        // Date the tokens locktime finish for the beneficiary. 
        uint256 startTime = releaseSchedule.tokenLockTime + releaseStartTime;
        
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
            if (timeCompleted < releaseSchedule.immediateAccessTimeWindow){
                timeCompleted = releaseSchedule.immediateAccessTimeWindow;
            }
        
            if (timeCompleted >= releaseSchedule.tokenReleaseDuration){
                timeCompleted = releaseSchedule.tokenReleaseDuration;
            }

            // `tokenReleaseDuration == 0` means everything is available right after the release lock time
            if (releaseSchedule.tokenReleaseDuration == 0){
                unlockedTokens = beneficiary.tokenBookedAmount;
            } else {
                unlockedTokens = (timeCompleted * beneficiary.tokenBookedAmount) / releaseSchedule.tokenReleaseDuration;
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
    
    modifier adminOnly(){
        require( (msg.sender == adminA) || (msg.sender == adminB) || (msg.sender == adminT) 
               , 'Only admins allowed'
               )
        ;
        _;
    }

    event NewAdminA(address adminA );
    
    function changeAdminA(address newAdminA) external adminOnly{
        if (adminA != newAdminA){
           emit NewAdminA(newAdminA);
           adminA = newAdminA;
        }
        // Notice we don't fail when there's not a NewAdminX defined,
        // this is on purpose, so the function becomes idempotent and
        // it is easier to programatically interact with while
        // deployed on testnet.  
    }

    event NewAdminB(address adminB );
    
    function changeAdminB(address newAdminB) external adminOnly{
        if (adminB != newAdminB){
           emit NewAdminB(newAdminB);
           adminB = newAdminB;
        }
    }

    event NewAdminT(address adminT );
    
    function changeAdminT(address newAdminT) external adminOnly{
        if (adminT != newAdminT){
           emit NewAdminT(newAdminT);
           adminT = newAdminT;
        }
    }

    event TokensBook(address beneficiary , uint256 tokenAmount, ReleaseType releaseSchedule); 

    function bookTokensFor( address beneficiary , uint256 tokenAmount, ReleaseType releaseSchedule) external adminOnly{
        require( avaliableTokensToRelease >= tokenAmount 
               , 'Not enough token to book'
               )
        ;
        require( beneficiaries[beneficiary].tokenBookedAmount == 0
               , 'Beneficiaries can only be set once'
               )
        ;
        require( tokenAmount > 0
               , 'More than 0 token needs to be booked to set a beneficiary'
               )
        ;
        avaliableTokensToRelease -= tokenAmount;
        
        emit TokensBook(beneficiary, tokenAmount, releaseSchedule);
        beneficiaries[beneficiary] = Beneficiary(releaseSchedule,0,tokenAmount);

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

    event ImmediateTokensSent(address beneficiary, uint256 amount);

    // Release tokens immediately without a release schedule.
    function immediateSendTokens(address beneficiary, uint256 amount) external adminOnly{

        require( avaliableTokensToRelease >= amount 
               , 'Not enough token avaliable'
               )
        ;

        avaliableTokensToRelease -= amount;
        emit ImmediateTokensSent(beneficiary, amount);
        
        tokenContract.transfer( beneficiary, amount );
    }

    //////////////////////////////////////////////////////////////////////////////////////////
    

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