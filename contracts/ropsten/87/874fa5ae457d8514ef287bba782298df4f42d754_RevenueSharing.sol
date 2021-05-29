/**
 *Submitted for verification at Etherscan.io on 2021-05-29
*/

pragma solidity ^0.5.11;

contract RevenueSharing {
	//這邊我將所有變量都定義為Public變量，這有助於幫助我們觀察到合約中更多細節
	//不過在實際編程中，出於安全考慮，設置變量和函數為Public時需要非常小心

	//宣告創造者的地址
	address public creator;

	//** mapping 用法參考以下備註網址
	//http://me.tryblockchain.org/solidity-mapping.html
mapping(uint => address payable) public shareholders;

	//uint一般用來表示貨幣的數量或日期，由於 Solidity 不支援 double/float 會截斷後面的小數。
uint public numShareholders;

	//事件可以用來通知外部實體，使外部實體可以透過輕用戶端很方便的查詢與存取事件
	//一般事件定義在合約狀態變數後面，並且第一個字母為大寫。事件名前可以加上 Log，避免和函數搞混
event LogDisburse(uint _amount, uint _numShareholders);

	//ShareRevenuePrepare()是構造函數，只會在合約部署時被調用一次
	//這個合約通過構造函數接收了一組地址數組，並將其保存於名為 shareholders 的數組中
function ShareRevenuePrepare(address payable[] memory addresses) public{
    creator = msg.sender;
    numShareholders = addresses.length;
    for (uint i=0; i< addresses.length; i++) {
        shareholders[i] = addresses[i];
    }
}

	//shareRevemue() 為這個智能合約中的唯一主函數
	//目的就是為了當定量以太幣被指定後，依照 shareholders 的數量來均分，並發送到每一個地址中。
function ShareRevenue() payable public returns (bool success) {
    uint amount = msg.value / numShareholders;
    for (uint i=0; i<numShareholders; i++) {
        if (!shareholders[i].send(amount)) revert();
    }
    emit LogDisburse(msg.value, numShareholders);
    return true;
	}
}