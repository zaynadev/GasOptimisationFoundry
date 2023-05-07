// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.0;

interface IGasContract {
  event AddedToWhitelist(address userAddress, uint256 tier);
  event supplyChanged(address indexed, uint256 indexed);
  event Transfer(address recipient, uint256 amount);
  event PaymentUpdated(
    address admin,
    uint256 ID,
    uint256 amount,
    string recipient
  );
  event WhiteListTransfer(address indexed);

  error InvalidAddress();
  error NotAnAdmin(address);
  error LevelExceedBoundry(uint256);
  error InsufficientBalance(uint256);
  error TargetAlreadyAnAdmin(address);
  error MaxNameLengthExceeded(uint256);
  error AmountShouldBeAbove3(uint256);
  error AmountShouldBeGreaterThanZero();
  error TargetAlreadyDeactivated(address);

  enum PaymentType {
    Unknown,
    BasicPayment,
    Refund,
    Dividend,
    GroupPayment
  }

  struct Payment {
    PaymentType paymentType;
    uint256 paymentID;
    bool adminUpdated;
    string recipientName; // max 8 characters
    address recipient;
    address admin; // administrators address
    uint256 amount;
  }

  struct History {
    uint256 lastUpdate;
    address updatedBy;
    uint256 blockNumber;
  }

  struct ImportantStruct {
    uint256 amount;
    uint256 valueA; // max 3 digits
    uint256 bigValue;
    uint256 valueB; // max 3 digits
    bool paymentStatus;
    address sender;
  }

}