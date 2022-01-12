/**
 *Submitted for verification at Etherscan.io on 2022-01-12
*/

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

// File: @openzeppelin\contracts\access\Ownable.sol

// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;


/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// File: contracts\KK_BBA.sol


pragma solidity >=0.7.0 <0.9.0;


contract KGI_Network is Ownable
{
    event ProductBought(address member, uint256 amount);
    event MemberAdded(address member, address sponsor, address upline);
    event MemberPaid(address member, uint256 amount);

    struct Member
    {
        address    wallet;
        uint256    balance;
        uint256    width;
        uint256    depth;
        address    sponsor;
        address    upline;
        address[]  frontline;
    }
    mapping(address => Member) private _MemberData;
    address[] private _membership;
    address[] private _nextPossibles;

    uint256 public minPayment = 5 ether; // 5 MATIC, about $10
    uint256 public minCommission = 0.001 ether; // $0.002
    uint256 public defaultWidth = 2;
    uint256 public companyWidth = 2;
    uint256 public defaultDepth = 2;

    uint256 public companyCommission = 10;
    uint256 public sponsorCommission = 20;
    uint256 public uplineCommission = 5;

    string public name;
 
    constructor(string memory _name)
    {
        name = _name;
        addMember(address(this), address(0), address(0));
        _MemberData[address(this)].width = companyWidth;
    }

    function memberPurchase(address member, address referral) public payable
    {
        address upline = _membership[0]; //default frontline to company
        address sponsor = _membership[0];

        // check not already a member, search _MemberData for the member address
        // if already a member, just skip to paying the commissions
        if(_MemberData[member].wallet == address(0))
        {
            // new member, so need to add
            // if no referral address passed, or referral address is not a member, company is sponsor
            if((referral == address(0)) || (_MemberData[referral].wallet == address(0)))
            {
                sponsor = _membership[0]; // no referral so sponsored by top
            }
            else
            {
                sponsor = referral;
                upline = referral;
            }

            // create an array of possible uplines, as we are just starting that will be just one entry, the sponsor
            // created in storage as needs to be expandable, but could get big!
            //delete _uplinePossibles;
            delete _nextPossibles;
            _nextPossibles.push(sponsor);

            // function checks for a free spot on the frontline of the passed possible uplines
            // builds a new array of frontlines and calls itself recursively down allowed levels (maxDepth)
            // if all allowed levels are full, starts new frontline leg
            upline = findNextFreeSpot(sponsor, _MemberData[sponsor].depth); 

            addMember(member, sponsor, upline);
        }
        else
        {
            sponsor = _MemberData[member].sponsor;
            upline = _MemberData[member].upline;
        }
        
        // so now we know where to start paying commission - sponsor is the sponsor; upline is the 1st upline
        
        uint256 companyPayment = msg.value * companyCommission / 100;     //company commission stays in contract
        uint256 sponsorPayment = msg.value * sponsorCommission / 100;     // deduct sponsor funds
        _MemberData[sponsor].balance += sponsorPayment;   // and give it to the sponsor

        // the rest starts going upline till none left or top reached
        // flat rate - x% to anyone upline
        uint256 distributableFunds = msg.value - (companyPayment + sponsorPayment);
        uint256 eachUplinePayment = msg.value * uplineCommission / 100;

        address payableMember = upline;
        while((distributableFunds > 0) && ( payableMember != address(0)))
        {
            _MemberData[payableMember].balance += eachUplinePayment;
            distributableFunds -= eachUplinePayment;
            payBalanceDue(payableMember);   // check members balance, if greater than minimum withdrawal, send funds
            payableMember = _MemberData[payableMember].upline;
        }
    }

    function findNextFreeSpot(address sponsor, uint256 maxDepth) private returns (address)
    {
        // function checks for a free spot on the frontline of the passed possible uplines
        // builds a new array of frontlines and calls itself recursively down allowed levels
        // if all allowed levels are full, starts new frontline leg
        address[] memory  _uplinePossibles = _nextPossibles;
        delete _nextPossibles;

        for(uint256 i=0; i<_uplinePossibles.length; i++)
        {
            // if their frontline isn't as wide as it's allowed to be, put one here
            if(_MemberData[_uplinePossibles[i]].frontline.length < _MemberData[_uplinePossibles[i]].width)
            {
                return _uplinePossibles[i];
            }
            else    // prepare array of next level, to test for an empty spot
            {
                for(uint256 j=0; j<_MemberData[_uplinePossibles[i]].frontline.length; j++)
                {
                    _nextPossibles.push(_MemberData[_uplinePossibles[i]].frontline[j]);
                }
            }
        }

        // need to test how deep we've gone... are we full and can start the next leg?
        // only sponsor can can expand their matrix, can;t be done by an upline placement
        
        uint256 nextLevel = maxDepth - 1;
        
        if (nextLevel <= 0)
        {
            // all levels full, so expand the matrix
            _MemberData[sponsor].width++;
            _MemberData[sponsor].depth++;
            return sponsor;
        }
        
        // if we get here, didnt find one in that level, but we have an array of that full level
        return findNextFreeSpot(sponsor, nextLevel);
    }

    function payBalanceDue(address member) private
    {
        if(_MemberData[member].balance > minPayment)
        {
            emit MemberPaid(member, _MemberData[member].balance);
            // and set balance to 0
        }
    }

    function addMember(address member, address sponsor, address upline) private
    {
       _membership.push(member);
        _MemberData[member].wallet = member;
        _MemberData[member].balance = 0;
        _MemberData[member].width = defaultWidth;
        _MemberData[member].depth = defaultDepth;
        _MemberData[member].sponsor = sponsor;
        _MemberData[member].upline = upline;

        _MemberData[upline].frontline.push(member);
     
        emit MemberAdded(member, sponsor, upline); 
    }

    /******************************** public view functions, probably required for website ******************/

    function getNumMembers() public view returns (uint256)
    {
        return _membership.length;
    }

    function getMemberData(address member) public view returns (address, address, address, uint256, uint256, uint256)
    {
        return(_MemberData[member].wallet, _MemberData[member].sponsor, _MemberData[member].upline, _MemberData[member].balance, _MemberData[member].width, _MemberData[member].depth);

    }

    function getMemberFrontline(address member) public view returns (address [] memory)
    {
        address[] memory frontline = new address[](_MemberData[member].frontline.length);

        for (uint i=0; i< _MemberData[member].frontline.length ; i++)
        {
            frontline[i] = _MemberData[member].frontline[i];
        }
        return(frontline);
    }

    /******************************** owner only functions ******************/

    function setMinPayment(uint256 _newMinPayment) public onlyOwner
    {
        minPayment = _newMinPayment;
    }

    function setMinCommission(uint256 _newMinCommission) public onlyOwner
    {
        minCommission = _newMinCommission;
    }

    function setDefaultWidth(uint256 _newDefaultWidth) public onlyOwner
    {
        defaultWidth = _newDefaultWidth;
    }

    function setMinDefaultDepth(uint256 _newDefaultDepth) public onlyOwner
    {
        defaultDepth = _newDefaultDepth;
    }

    function setCompanyCommission(uint256 _newCompanyCommission) public onlyOwner
    {
        companyCommission = _newCompanyCommission;
    }

    function setSponsorCommission(uint256 _newSponsorCommission) public onlyOwner
    {
        sponsorCommission = _newSponsorCommission;
    }

    function setUplineCommission(uint256 _newUplineCommission) public onlyOwner
    {
        uplineCommission = _newUplineCommission;
    }

    /**************************************************** test purposes only ******************************/

    function clearMembership() public onlyOwner  
    {     
        for (uint i=0; i< _membership.length ; i++)
        {
            _MemberData[_membership[i]].wallet = address(0);
            _MemberData[_membership[i]].balance = 0;
            _MemberData[_membership[i]].width = 0;
            _MemberData[_membership[i]].depth = 0;
            _MemberData[_membership[i]].sponsor = address(0);
            _MemberData[_membership[i]].upline = address(0);
        }
        delete _membership;

        // re-initialise with top spot (company)      
        addMember(address(this), address(0), address(0));
        _MemberData[address(this)].width = companyWidth;
    }

}