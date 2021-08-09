/**
 *Submitted for verification at BscScan.com on 2021-08-08
*/

/**
 *Submitted for verification at BscScan.com on 2021-06-05
*/

/**
 *Submitted for verification at BscScan.com on 2021-06-05
*/

/**
 *Submitted for verification at BscScan.com on 2021-06-02
*/
// SPDX-License-Identifier: MIT
pragma solidity  ^0.6.1;


interface IBEP20 {
  /**
   * @dev Returns the amount of tokens in existence.
   */
  function totalSupply() external view returns (uint256);

  /**
   * @dev Returns the token decimals.
   */
  function decimals() external view returns (uint8);

  /**
   * @dev Returns the token symbol.
   */
  function symbol() external view returns (string memory);

  /**
  * @dev Returns the token name.
  */
  function name() external view returns (string memory);

  /**
   * @dev Returns the bep token owner.
   */
  function getOwner() external view returns (address);

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
  function allowance(address _owner, address spender) external view returns (uint256);

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
  function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

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




interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}



interface IERC721 is IERC165 {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(address from, address to, uint tokenId) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address from, address to, uint tokenId) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint tokenId) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint tokenId) external view returns (address operator);

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool _approved) external;

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);

    /**
      * @dev Safely transfers `tokenId` token from `from` to `to`.
      *
      * Requirements:
      *
      * - `from` cannot be the zero address.
      * - `to` cannot be the zero address.
      * - `tokenId` token must exist and be owned by `from`.
      * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
      * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
      *
      * Emits a {Transfer} event.
      */
    function safeTransferFrom(address from, address to, uint tokenId, bytes calldata data) external;
}

interface IERC721Receiver {
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721.onERC721Received.selector`.
     */
    function onERC721Received(address operator, address from, uint tokenId, bytes calldata data) external returns (bytes4);
}



contract Wizshot 
   
   {
     //define the admin of ICO 
     address public owner;
     address public inputtoken;
     address public nftaddress;
     
     bool public claimenabled = false; 
      
     address public wizard = 0x5066C68cAe3B9BdaCD6A1A37c90F2d1723559D18;
     uint256 public wizardlimit = 200 * 10 **18;
    
     uint256 public redeemstarttingrange;
     uint256 public redeemendrange;
     uint256 public claimIndex;
    
     address public nftAdmin = 0x4D1294c48EaCF4D5242e68509D2703117B6440B4;
    
     mapping (address => uint256) public userinvested;
     address[] public investors;
     mapping (address => bool) public existinguser;
     
     uint256 public maxInvestment = 0;   
    
     uint public icoTarget;
     uint public receivedFund=0;
      
     event Invest(address indexed user, uint256 indexed amount);
     event Claim(address indexed user, uint256 indexed tokenid);

     modifier onlyOwner() {
          require(msg.sender == owner);
           _;
    }   
    
    
        function transferOwnership(address _newowner) public onlyOwner {
            
            owner = _newowner;
        } 
 
         constructor () public  {
         
             owner = msg.sender;
         }
 

     function trade() public {
         
         require (claimenabled == true, "Claim not enabled");     
         
          uint256 _amount = maxInvestment;
          
          IBEP20 wiz;
          wiz = IBEP20(wizard);
    
          // check naut balance 
           require (wiz.balanceOf(msg.sender) >= wizardlimit, "Hold Wizard to Participate");
    
          //check for hard cap
          require(icoTarget >= receivedFund + _amount, "Target Achieved. Investment not accepted");
     
          //  require(_amount > 0 , "min Investment not zero");
          uint256 checkamount = userinvested[msg.sender] + _amount;
     
          //check maximum investment        
          require(checkamount <= maxInvestment, "Already Invested"); 
     
          // check for existinguser
          if (existinguser[msg.sender]==false) {
         
            existinguser[msg.sender] = true;
            investors.push(msg.sender);
          }
     
           userinvested[msg.sender] += _amount; 
           receivedFund = receivedFund + _amount;
           
           IBEP20(inputtoken).transferFrom(msg.sender,address(this), _amount);  
           
           
           IERC721 nft;
           nft = IERC721(nftaddress); 
           
           uint256 nftid = redeemstarttingrange + claimIndex; 
           assert (nftid <= redeemendrange);   
           claimIndex += 1; 
     
          nft.safeTransferFrom(nftAdmin, msg.sender, nftid);
     
       emit Claim(msg.sender,nftid);
     }
     
     

    function remainigContribution(address _owner) public view returns (uint256) {
        
        uint256 remaining = maxInvestment - userinvested[_owner];
        return remaining;
    }
    
    
    
    function checkbalance() public view returns(uint256 _balance) {
        
        return IBEP20(inputtoken).balanceOf(address(this));  
    }
    
   

    function withdarwInputToken(address _admin) public onlyOwner{
        
       uint256 raisedamount = IBEP20(inputtoken).balanceOf(address(this));
       IBEP20(inputtoken).transfer(_admin, raisedamount);
    }
    
    
       function setclaimStatus(bool _status) external onlyOwner {
        
        claimenabled = _status;
         }
    
    
       function setwizardlimit(uint256 _newlimit) public onlyOwner {
           
        wizardlimit = _newlimit;   
       }
       
       
       function changenftadmin(address _add) public onlyOwner  {
           
          nftAdmin = _add; 
       }
       
       function changeIcotarget(uint256 _newvalue) public onlyOwner {
           
          icoTarget = _newvalue; 
       }
       
       function changeredeemeendlimit(uint256 _newvalue) public onlyOwner {
           
          redeemendrange = _newvalue; 
       }
       
       function changeredeemstartlimit(uint256 _newvalue) public onlyOwner {
           
          redeemstarttingrange = _newvalue; 
       }
       
       function changenftaddress(address _add) public onlyOwner {
           
           nftaddress = _add;
       }
       
       function changetokenaddress(address _add) public onlyOwner {
           
           wizard = _add;
       }
       
    
      function resetICO() public onlyOwner {
        
         for (uint256 i = 0; i < investors.length; i++) {
             
            if (existinguser[investors[i]]==true)
            {
                  existinguser[investors[i]]=false;
                  userinvested[investors[i]] = 0;
            }
        }
        
        //require(IBEP20(outputtoken).balanceOf(address(this)) <= 0, "Ico is not empty");
        require(IBEP20(inputtoken).balanceOf(address(this)) <= 0, "Ico is not empty");
        
        icoTarget = 0;
        receivedFund = 0;
        maxInvestment = 0;
        inputtoken  =  0x0000000000000000000000000000000000000000;
        nftaddress =   0x0000000000000000000000000000000000000000;
        claimenabled = false;
        redeemstarttingrange = 0;
        redeemendrange = 0;
        claimIndex = 0;
        
        delete investors;
    }
    
    

        
    function initializeICO(address _inputtoken, address _nftaddress, uint256 _icotarget, uint256 _maxinvestment, uint256 _nftstartingrange, uint256 _nftendrange) public onlyOwner 
    {
        inputtoken = _inputtoken;
        nftaddress = _nftaddress;
        
        icoTarget = _icotarget;
        redeemstarttingrange = _nftstartingrange;
        redeemendrange = _nftendrange;
        
        require (icoTarget > _maxinvestment, "Incorrect maxinvestment value");
        
        maxInvestment = _maxinvestment;
    }
    

}