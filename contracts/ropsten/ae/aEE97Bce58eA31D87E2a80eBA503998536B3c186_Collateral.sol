/**
 *Submitted for verification at Etherscan.io on 2021-07-08
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

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
    function safeTransferFrom(address from, address to, uint256 tokenId) external;

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
    function transferFrom(address from, address to, uint256 tokenId) external;

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
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

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
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes calldata data) external;
}

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

// from cryptozombies lesson5. This library prevent overflow problems.
library SafeMath {

  /**
  * @dev Multiplies two numbers, throws on overflow.
  */
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0) {
      return 0;
    }
    uint256 c = a * b;
    assert(c / a == b);
    return c;
  }

  /**
  * @dev Integer division of two numbers, truncating the quotient.
  */
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn't hold
    return c;
  }

  /**
  * @dev Substracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
  */
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  /**
  * @dev Adds two numbers, throws on overflow.
  */
  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }
}

contract Collateral {
    
    // creditorは債権者（＝担保権者）のアドレスであり,debtorは債務者（＝担保設定者）のアドレスである。
    // debtBalanceは総債務額から、債権者アドレスに送金されていない額を引いた額である。
    // dueDateは弁済期である。
    address public creditor;
    address public debtor;
    uint debtBalance;
    uint dueDate;
    
    // SafeMath libraryの呼び出し
    using SafeMath for uint;
    
    // インターフェイスの定義
    IERC721 erc721CollateralTokenContract;
    IERC20 erc20LoanTokenContract;
    
    // 債務者及び債権者のアドレス並びに貸付トークン及び担保トークンのコントラクトアドレスは以下のとおり、契約の性質上固定しておく。
    // decimalsが18であることを前提にdebtBalanceなどを入力する必要がある。
    constructor(
        address _creditor, 
        address _debtor, 
        address _erc721CollateralTokenAddress, 
        address _erc20LoanTokenAddress,
        uint _debtBalance,
        uint _setDueDate
        ) {
        creditor = _creditor;
        debtor = _debtor;
        erc721CollateralTokenContract = IERC721(_erc721CollateralTokenAddress);
        erc20LoanTokenContract = IERC20(_erc20LoanTokenAddress);
        debtBalance = _debtBalance;
        dueDate = block.timestamp + _setDueDate;
    }
    
    // debtBalanceを確認するための関数
    function getDebtBalance() public view returns (uint) {
        return debtBalance;
    }
    
    // dueDateを確認するための関数
    function getDueDate() public view returns (uint) {
        return dueDate;
    }
    
    // 債務の額を設定する関数。債務の額を増やすのであれば、債務者が自由に債務の額を設定できるようになっている。
    // 債務の額を減少する方向で事後的に合意したのであれば、changeDebtBalance関数を実行すればよい。
    // msg.senderは関数を実行しようとしたアドレスである。
    function ChangeDebtBalanceByD(uint _debtBalance) public {
        require(msg.sender == debtor);
        require(debtBalance <= _debtBalance);
        debtBalance = _debtBalance;
    }
    
    // 債務の額を変更する関数。債務の額を減らすのであれば、債務者が自由に債務の額を設定できるようになっている。
    // 債務の額を上昇させる方向で事後的に合意したのであれば、setAndChangeDebtBalance関数を実行すればよい。
    function changeDebtBalanceByC(uint _debtBalance) public {
        require(msg.sender == creditor);
        require(debtBalance > _debtBalance);
        debtBalance = _debtBalance;
    }
    

//  債務者がloantokenを引き出すための関数が実装されていたが、
//  債務者が担保を引き出した後にこの関数の実行を制限する機能を実装するのがやや面倒であること、
//  債務者がloantokenを引き出すこと自体が消費貸借契約の考え方と整合しにくいこと、
//  債務者が送り間違えたloantokenは債権者が引き出し可能であり、危機時期以外の円満な債権者債務者関係であれば、債務者の送り間違えによって特段のトラブルは生じにくいこと
//  そもそも債務者はloantokenを送り間違えるべきではないこと
//  などを考慮した結果この関数は削除する。
//     function returnLoanTokenByD(address _to, uint _amount) public {
// 	    require(msg.sender == debtor);
// 	    _amount = _amount.mul(10e17);
// 	    erc20LoanTokenContract.transfer(_to, _amount);
// 	}
	
	
	// 債権者がコントラクトアドレスに供与した返済金を引き出すための関数
    // 債権者が返済金を引き出した場合、残債務額を示すdebtBalanceが引き出した額だけ減少するようになっている。
    // この関数実行時に、任意のアドレスを_toに入れることでコントラクトアドレス内のerc20TOKENを_amount分だけ_toアドレスに送ることができる。
    // オーバーフロー防止のためSafeMath関数を使用している。
    function returnLoanTokenByC(address _to, uint _amount) public {
	    require(msg.sender == creditor);
	    debtBalance = debtBalance.sub(_amount);
	    erc20LoanTokenContract.transfer(_to, _amount);
	}
    
    // 債務者が債務の弁済後に、供与した担保を取り戻すための関数
    // debtBalanceよりも多くのLoanTokengがこのコントラクトアドレスに送られていれば実行可能である。
    // thisは、このコントラクトのコントラクトアドレスを示す。
	function returnCollateralByD(address _to, uint tokenId) public {
	    require(msg.sender == debtor);
	    require(debtBalance <= erc20LoanTokenContract.balanceOf(address(this)) );
	    erc721CollateralTokenContract.transferFrom(address(this), _to, tokenId);
	}
    
    // 弁済期を再設定するための関数
    // 既に設定された弁済期よりも長い弁済期しか設定できないため、設定者が債権者のみでも債務者保護に資する。
    // _setDueDateは秒数で入力すること
    // nowはある時点から関数を実行した現在までに経過した秒数である。
    function setDueDateByC(uint _setDueDate) public {
        require(msg.sender == creditor);
        require(dueDate < block.timestamp + _setDueDate);
        dueDate = block.timestamp + _setDueDate;
    }
    
    // 弁済期を設定するための関数
    // 既に設定された弁済期よりも短い弁済期しか設定できないため、設定者が債務者のみでも債権者を害するわけではない。
    // _setDueDateは秒数で入力すること
    // nowはある時点から関数を実行した現在までに経過した秒数である。
    function setDueDateByD(uint _setDueDate) public {
        require(msg.sender == debtor);
        require(dueDate > block.timestamp + _setDueDate);
        dueDate = block.timestamp + _setDueDate;
    }


	
    // 弁済期経過後に債権者が担保を実行して自己の下に担保トークンを移すための関数
    // debtBalanceがコントラクトアドレスに送られたLoanTokenの額に満たないことが条件である。
	function executeCollateralByC(address _to, uint tokenId) public {
	    require(msg.sender == creditor);
	    require(block.timestamp > dueDate);
	    require(debtBalance > erc20LoanTokenContract.balanceOf(address(this)));
	    erc721CollateralTokenContract.transferFrom(address(this), _to, tokenId);
	}
	
}