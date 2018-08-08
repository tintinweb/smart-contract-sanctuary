pragma solidity ^0.4.18;

/************************************************** */
/* WhenHub TokenVesting Contract                    */
/* Author: Nik Kalyani  nik@whenhub.com             */
/* Copyright (c) 2018 CalendarTree, Inc.            */
/* https://interface.whenhub.com                    */
/************************************************** */
contract TokenVesting {
    using SafeMath for uint256;


    /* VestingGrant is used to implement business rules regarding token vesting       */
    struct VestingGrant {
        bool isGranted;                                                 // Flag to indicate grant was issued
        address issuer;                                                 // Account that issued grant
        address beneficiary;                                            // Beneficiary of grant
        uint256 grantJiffys;                                            // Number of Jiffys granted
        uint256 startTimestamp;                                         // Start date/time of vesting
        uint256 cliffTimestamp;                                         // Cliff date/time for vesting
        uint256 endTimestamp;                                           // End date/time of vesting
        bool isRevocable;                                               // Whether issuer can revoke and reclaim Jiffys
        uint256 releasedJiffys;                                         // Number of Jiffys already released
    }

    mapping(address => VestingGrant) private vestingGrants;             // Token grants subject to vesting
    address[] private vestingGrantLookup;                               // Lookup table of token grants

    uint private constant GENESIS_TIMESTAMP = 1514764800;                       // Jan 1, 2018 00:00:00 UTC (arbitrary date/time for timestamp validation)
    uint private constant ONE_MONTH = 2629743;
    uint private constant ONE_YEAR = 31556926;
    uint private constant TWO_YEARS = 63113852;
    uint private constant THREE_YEARS = 94670778;

    bool private initialized = false;

    /* Vesting Events */
    event Grant             // Fired when an account grants tokens to another account on a vesting schedule
                            (
                                address indexed owner, 
                                address indexed beneficiary, 
                                uint256 valueVested,
                                uint256 valueUnvested
                            );

    event Revoke            // Fired when an account revokes previously granted unvested tokens to another account
                            (
                                address indexed owner, 
                                address indexed beneficiary, 
                                uint256 value
                            );

    // This contract does not accept any Ether
    function() public {
        revert();
    }

    string public name = "TokenVesting";

    // Controlling WHENToken contract (cannot be changed)
    WHENToken whenContract;

    modifier requireIsOperational() 
    {
        require(whenContract.isOperational());
        _;
    }

    /**
    * @dev Constructor
    *
    * @param whenTokenContract Address of the WHENToken contract
    */
    function TokenVesting
                                (
                                    address whenTokenContract
                                ) 
                                public
    {
        whenContract = WHENToken(whenTokenContract);

    }

     /**
    * @dev Initial token grants for various accounts
    *
    * @param companyAccount Account representing the Company for granting tokens
    * @param partnerAccount Account representing the Partner for granting tokens
    * @param foundationAccount Account representing the Foundation for granting tokens
    */    
    function initialize         (
                                    address companyAccount,
                                    address partnerAccount, 
                                    address foundationAccount
                                )
                                external
    {
        require(!initialized);

        initialized = true;

        uint256 companyJiffys;
        uint256 partnerJiffys;
        uint256 foundationJiffys;
        (companyJiffys, partnerJiffys, foundationJiffys) = whenContract.getTokenAllocations();

        // Grant tokens for current and future use of company
        // One-third initial grant; two-year vesting for balance starting after one year
        uint256 companyInitialGrant = companyJiffys.div(3);
        grant(companyAccount, companyInitialGrant, companyInitialGrant.mul(2), GENESIS_TIMESTAMP + ONE_YEAR, 0, TWO_YEARS, false);

        // Grant vesting tokens to partner account for use in incentivizing partners
        // Three-year vesting, with six-month cliff
        grant(partnerAccount, 0, partnerJiffys, GENESIS_TIMESTAMP, ONE_MONTH.mul(6), THREE_YEARS, true);

        // Grant vesting tokens to foundation account for charitable use
        // Three-year vesting, with six-month cliff
        grant(foundationAccount, 0, foundationJiffys, GENESIS_TIMESTAMP, ONE_MONTH.mul(6), THREE_YEARS, true);
    }

    /**
    * @dev Grants a beneficiary Jiffys using a vesting schedule
    *
    * @param beneficiary The account to whom Jiffys are being granted
    * @param vestedJiffys Fully vested Jiffys that will be granted
    * @param unvestedJiffys Jiffys that are granted but not vested
    * @param startTimestamp Date/time when vesting begins
    * @param cliffSeconds Date/time prior to which tokens vest but cannot be released
    * @param vestingSeconds Vesting duration (also known as vesting term)
    * @param revocable Indicates whether the granting account is allowed to revoke the grant
    */   
    function grant
                            (
                                address beneficiary, 
                                uint256 vestedJiffys,
                                uint256 unvestedJiffys, 
                                uint256 startTimestamp, 
                                uint256 cliffSeconds, 
                                uint256 vestingSeconds, 
                                bool revocable
                            ) 
                            public 
                            requireIsOperational
    {
        require(beneficiary != address(0));
        require(!vestingGrants[beneficiary].isGranted);         // Can&#39;t have multiple grants for same account
        require((vestedJiffys > 0) || (unvestedJiffys > 0));    // There must be Jiffys that are being granted

        require(startTimestamp >= GENESIS_TIMESTAMP);           // Just a way to prevent really old dates
        require(vestingSeconds > 0);
        require(cliffSeconds >= 0);
        require(cliffSeconds < vestingSeconds);

        whenContract.vestingGrant(msg.sender, beneficiary, vestedJiffys, unvestedJiffys);

        // The vesting grant is added to the beneficiary and the vestingGrant lookup table is updated
        vestingGrants[beneficiary] = VestingGrant({
                                                    isGranted: true,
                                                    issuer: msg.sender,                                                   
                                                    beneficiary: beneficiary, 
                                                    grantJiffys: unvestedJiffys,
                                                    startTimestamp: startTimestamp,
                                                    cliffTimestamp: startTimestamp + cliffSeconds,
                                                    endTimestamp: startTimestamp + vestingSeconds,
                                                    isRevocable: revocable,
                                                    releasedJiffys: 0
                                                });

        vestingGrantLookup.push(beneficiary);

        Grant(msg.sender, beneficiary, vestedJiffys, unvestedJiffys);   // Fire event

        // If the cliff time has already passed or there is no cliff, then release
        // any Jiffys for which the beneficiary is already eligible
        if (vestingGrants[beneficiary].cliffTimestamp <= now) {
            releaseFor(beneficiary);
        }
    }

    /**
    * @dev Gets current grant balance for caller
    *
    */ 
    function getGrantBalance() 
                            external 
                            view 
                            returns(uint256) 
    {
       return getGrantBalanceOf(msg.sender);        
    }

    /**
    * @dev Gets current grant balance for an account
    *
    * The return value subtracts Jiffys that have previously
    * been released.
    *
    * @param account Account whose grant balance is returned
    *
    */ 
    function getGrantBalanceOf
                            (
                                address account
                            ) 
                            public 
                            view 
                            returns(uint256) 
    {
        require(account != address(0));
        require(vestingGrants[account].isGranted);
        
        return(vestingGrants[account].grantJiffys.sub(vestingGrants[account].releasedJiffys));
    }


    /**
    * @dev Releases Jiffys that have been vested for caller
    *
    */ 
    function release() 
                            public 
    {
        releaseFor(msg.sender);
    }

    /**
    * @dev Releases Jiffys that have been vested for an account
    *
    * @param account Account whose Jiffys will be released
    *
    */ 
    function releaseFor
                            (
                                address account
                            ) 
                            public 
                            requireIsOperational 
    {
        require(account != address(0));
        require(vestingGrants[account].isGranted);
        require(vestingGrants[account].cliffTimestamp <= now);
        
        // Calculate vesting rate per second        
        uint256 jiffysPerSecond = (vestingGrants[account].grantJiffys.div(vestingGrants[account].endTimestamp.sub(vestingGrants[account].startTimestamp)));

        // Calculate how many jiffys can be released
        uint256 releasableJiffys = now.sub(vestingGrants[account].startTimestamp).mul(jiffysPerSecond).sub(vestingGrants[account].releasedJiffys);

        // If the additional released Jiffys would cause the total released to exceed total granted, then
        // cap the releasable Jiffys to whatever was granted.
        if ((vestingGrants[account].releasedJiffys.add(releasableJiffys)) > vestingGrants[account].grantJiffys) {
            releasableJiffys = vestingGrants[account].grantJiffys.sub(vestingGrants[account].releasedJiffys);
        }

        if (releasableJiffys > 0) {
            // Update the released Jiffys counter
            vestingGrants[account].releasedJiffys = vestingGrants[account].releasedJiffys.add(releasableJiffys);
            whenContract.vestingTransfer(vestingGrants[account].issuer, account, releasableJiffys);
        }
    }

    /**
    * @dev Returns a lookup table of all vesting grant beneficiaries
    *
    */ 
    function getGrantBeneficiaries() 
                            external 
                            view 
                            returns(address[]) 
    {
        return vestingGrantLookup;        
    }

    /**
    * @dev Revokes previously issued vesting grant
    *
    * For a grant to be revoked, it must be revocable.
    * In addition, only the unreleased tokens can be revoked.
    *
    * @param account Account for which a prior grant will be revoked
    */ 
    function revoke
                            (
                                address account
                            ) 
                            public 
                            requireIsOperational 
    {
        require(account != address(0));
        require(vestingGrants[account].isGranted);
        require(vestingGrants[account].isRevocable);
        require(vestingGrants[account].issuer == msg.sender); // Only the original issuer can revoke a grant

        // Set the isGranted flag to false to prevent any further
        // actions on this grant from ever occurring
        vestingGrants[account].isGranted = false;        
        
        // Get the remaining balance of the grant
        uint256 balanceJiffys = vestingGrants[account].grantJiffys.sub(vestingGrants[account].releasedJiffys);
        Revoke(vestingGrants[account].issuer, account, balanceJiffys);

        // If there is any balance left, return it to the issuer
        if (balanceJiffys > 0) {
            whenContract.vestingTransfer(msg.sender, msg.sender, balanceJiffys);
        }
    }

}

contract WHENToken {

    function isOperational() public view returns(bool);
    function vestingGrant(address owner, address beneficiary, uint256 vestedJiffys, uint256 unvestedJiffys) external;
    function vestingTransfer(address owner, address beneficiary, uint256 jiffys) external;
    function getTokenAllocations() external view returns(uint256, uint256, uint256);
}

/*
LICENSE FOR SafeMath and TokenVesting

The MIT License (MIT)

Copyright (c) 2016 Smart Contract Solutions, Inc.

Permission is hereby granted, free of charge, to any person obtaining
a copy of this software and associated documentation files (the
"Software"), to deal in the Software without restriction, including
without limitation the rights to use, copy, modify, merge, publish,
distribute, sublicense, and/or sell copies of the Software, and to
permit persons to whom the Software is furnished to do so, subject to
the following conditions:

The above copyright notice and this permission notice shall be included
in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS
OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY
CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
*/


library SafeMath {
/* Copyright (c) 2016 Smart Contract Solutions, Inc. */
/* See License at end of file                        */

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
        return 0;
        }
        uint256 c = a * b;
        assert(c / a == b);
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        // assert(b > 0); // Solidity automatically throws when dividing by 0
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        assert(c >= a);
        return c;
    }
}