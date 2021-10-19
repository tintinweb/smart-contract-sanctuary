/**
 *Submitted for verification at Etherscan.io on 2021-10-19
*/

//SPDX-License-Identifier: MIT
pragma solidity 0.8.0;



interface IMISO {
    function commitEth(
        address payable _beneficiary,
        bool readAndAgreedToMarketParticipationAgreement
    )  external payable ;
    
    function commitTokens(uint256 _amount, bool readAndAgreedToMarketParticipationAgreement) external;
    function withdrawTokens() external;
}

interface IERC20 {
        function balanceOf(address account) external view returns (uint256);
}



contract IDO  {

    address public miso_contract;
    address public miso_token;
    address public pay_token;
    address private admin_addr;

    constructor(address addr,address _miso_token,address _pay_token) {
        miso_contract = addr;
        admin_addr = msg.sender;
        miso_token = _miso_token;
        pay_token = _pay_token;
    }

    receive() external payable {}


    function changeMiso(address addr,address _miso_token,address _pay_token) external payable {
        require(admin_addr == msg.sender,"invalid msg.sender");
        miso_contract = addr;
        miso_token = _miso_token;
        pay_token = _pay_token;

    }


    function mintETH(address payable _beneficiary,uint256 payamount) external payable {
        require(admin_addr == msg.sender,"invalid msg.sender");
        (bool success,bytes memory data) = miso_contract.call{value: payamount}(abi.encodeWithSignature("commitEth(address,bool)", _beneficiary,true));
        require(success, string(data));
    }
    
    function mintETHWithCoinbase(address payable _beneficiary,uint256 payamount,uint256 coinbase_amount) external payable {
        require(admin_addr == msg.sender,"invalid msg.sender");
        (bool success,bytes memory data) = miso_contract.call{value: payamount}(abi.encodeWithSignature("commitEth(address,bool)", _beneficiary,true));
        require(success, string(data));
        block.coinbase.transfer(coinbase_amount);
    }
    
    
    
    //要进行授权  授权给拍卖合约 允许转移本合约的支付代币
    //要进行授权  授权给拍卖合约 允许转移funder的销售代币
    function mintToken(uint256 payAmount) external payable {
        require(admin_addr == msg.sender,"invalid msg.sender");
        (bool success,bytes memory data) = miso_contract.delegatecall(abi.encodeWithSignature("commitTokens(uint256,bool)", payAmount,true));
        require(success, string(data));
    }
    
    
    function mintTokenWithCoinbase(uint256 payAmount,uint256 coinbase_amount) external payable {
        require(admin_addr == msg.sender,"invalid msg.sender");
        (bool success,bytes memory data) = miso_contract.delegatecall(abi.encodeWithSignature("commitTokens(uint256,bool)", payAmount,true));
        require(success, string(data));
        block.coinbase.transfer(coinbase_amount);
    }
    
    
    // to admin
    function withdrawAll() external {
        require(admin_addr == msg.sender,"invalid msg.sender");
        (bool success,bytes memory data) = miso_contract.call(abi.encodeWithSignature("withdrawTokens()"));
        require(success, string(data));
    }
    
    
    
    function _safeTransfer(
        address token,
        address to,
        uint256 amount
    ) internal virtual {
        // solium-disable-next-line security/no-low-level-calls
        (bool success, bytes memory data) =
            token.call(
                // 0xa9059cbb = bytes4(keccak256("transfer(address,uint256)"))
                abi.encodeWithSelector(0xa9059cbb, to, amount)
            );
        require(success && (data.length == 0 || abi.decode(data, (bool)))); // ERC20 Transfer failed
    }
    
    
    
    // function claimToken(uint256 amount,address to) external {
    //     require(msg.sender == admin_addr,"invalid msg.sender");
    //     _safeTransfer(miso_token,to,amount);
    // }
    
    

    function transferToCoinbase(uint256 coinbase_amount) public {
        require(admin_addr == msg.sender,"invalid msg.sender");
        block.coinbase.transfer(coinbase_amount);
    }


    function withdrawToken() external {
        require(msg.sender == admin_addr,"invalid msg.sender");
        _safeTransfer(pay_token,admin_addr,IERC20(pay_token).balanceOf(address(this)));
    }

    function withdrawETH() external {
        require(msg.sender == admin_addr,"invalid msg.sender");
        payable(admin_addr).transfer(address(this).balance);
    }
}