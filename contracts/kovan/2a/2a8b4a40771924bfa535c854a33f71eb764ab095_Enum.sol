/**
 *Submitted for verification at Etherscan.io on 2022-01-02
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.10 <0.9.0;

contract Enum {
    // 物流狀態
    enum Status {
        Pending,    // 0
        Shipped,    // 1
        Accepted,   // 2
        Rejected,   // 3
        Canceled    // 4
    }

    // 聲明列舉變數但不賦值時, 預設值為 default(T)
    // 此例中為 Pending
    Status public status;

    // 取得狀態
    function get() public view returns (Status) {
        return status;
    }

    // 設置狀態
    // 傳入參數為 uint
    function set(Status _status) public {
        status = _status;
    }

    // 將狀態設置為 Canceled
    function cancel() public {
        status = Status.Canceled;
    }

    // 重置狀態
    // delete 關鍵字將狀態重置為 default(T)
    function reset() public {
        delete status;
    }
}