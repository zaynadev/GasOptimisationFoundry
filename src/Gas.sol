// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

import "./Ownable.sol";

contract Constants {
    uint256 public tradeFlag = 1;
    uint256 public basicFlag = 0;
    uint256 public dividendFlag = 1;                        
}

contract GasContract is Ownable, Constants {
    error OnlyAdminOrOwner();
    error InvalidTier(uint8);
    error Anomally();
    error InsufficientBalance();
    error ZeroAddress();
    error NameTooLong();
    error AmountShouldExceed3();
    
    uint256 public totalSupply = 0; // cannot be updated
    uint256 public paymentCounter = 0;
    mapping(address => uint256) public balances;
    uint256 public tradePercent = 12;
    address public contractOwner;
    uint256 public tradeMode = 0;
    mapping(address => uint256) public whitelist;
    address[5] public administrators;
    bool public isReady = false;
    uint256 wasLastOdd = 1;
    mapping(address => uint256) public isOddWhitelistUser;
    
    struct ImportantStruct {
        uint256 amount;
        uint256 valueA; // max 3 digits
        uint256 bigValue;
        uint256 valueB; // max 3 digits
        bool paymentStatus;
        address sender;
    }
    mapping(address => ImportantStruct) public whiteListStruct;

    event AddedToWhitelist(address userAddress, uint256 tier);

    function onlyAdminOrOwner() internal view {
        address senderOfTx = _msgSender();
        require(checkForAdmin(senderOfTx) || senderOfTx == contractOwner, "Denied");
    }

    modifier checkIfWhiteListed(address sender) {
        address senderOfTx = _msgSender();
        uint256 usersTier = whitelist[senderOfTx];
        require(
            senderOfTx == sender && usersTier > 0 && usersTier < 4,
            "Not whiteListed"
        );
        _;
    }

    event supplyChanged(address indexed, uint256 indexed);
    event Transfer(address recipient, uint256 amount);
    event PaymentUpdated(
        address admin,
        uint256 ID,
        uint256 amount,
        string recipient
    );
    event WhiteListTransfer(address indexed);

    constructor(address[] memory _admins, uint256 _totalSupply) {
        contractOwner = _msgSender();
        totalSupply = _totalSupply;

        for (uint256 ii = 0; ii < administrators.length; ii++) {
            if (_admins[ii] != address(0)) {
                administrators[ii] = _admins[ii];
                if (_admins[ii] == contractOwner) {
                    balances[contractOwner] = totalSupply;
                } else {
                    balances[_admins[ii]] = 0;
                }
                if (_admins[ii] == contractOwner) {
                    emit supplyChanged(_admins[ii], totalSupply);
                } else if (_admins[ii] != contractOwner) {
                    emit supplyChanged(_admins[ii], 0);
                }
            }
        }
    }

    function checkForAdmin(address _user) public view returns (bool admin_) {
        bool admin = false;
        for (uint256 ii = 0; ii < administrators.length; ii++) {
            if (administrators[ii] == _user) {
                admin = true;
            }
        }
        return admin;
    }

    function balanceOf(address _user) public view returns (uint256 balance_) {
        uint256 balance = balances[_user];
        return balance;
    }

    function getTradingMode() public view returns (bool mode_) {
        bool mode = false;
        if (tradeFlag == 1 || dividendFlag == 1) {
            mode = true;
        } else {
            mode = false;
        }
        return mode;
    }

    function transfer(
        address _recipient,
        uint256 _amount,
        string calldata _name
    ) public returns (bool status_) {
        address senderOfTx = _msgSender();
        if(balances[senderOfTx] < _amount) revert InsufficientBalance();
        if(bytes(_name).length >= 9) revert NameTooLong();

        balances[senderOfTx] -= _amount;
        balances[_recipient] += _amount;
        emit Transfer(_recipient, _amount);

        return true;
    }

    // function updatePayment(
    //     address _user,
    //     uint256 _ID,
    //     uint256 _amount,
    //     PaymentType _type
    // ) public {
    //     onlyAdminOrOwner();
    //     require(
    //         _ID > 0,
    //         "Gas Contract - Update Payment function - ID must be greater than 0"
    //     );
    //     require(
    //         _amount > 0,
    //         "Gas Contract - Update Payment function - Amount must be greater than 0"
    //     );
    //     require(
    //         _user != address(0),
    //         "Gas Contract - Update Payment function - Administrator must have a valid non zero address"
    //     );

    //     address senderOfTx = _msgSender();

    //     for (uint256 ii = 0; ii < payments[_user].length; ii++) {
    //         if (payments[_user][ii].paymentID == _ID) {
    //             payments[_user][ii].adminUpdated = true;
    //             payments[_user][ii].admin = _user;
    //             payments[_user][ii].paymentType = _type;
    //             payments[_user][ii].amount = _amount;
    //             bool tradingMode = getTradingMode();
    //             addHistory(_user, tradingMode);
    //             emit PaymentUpdated(
    //                 senderOfTx,
    //                 _ID,
    //                 _amount,
    //                 payments[_user][ii].recipientName
    //             );
    //         }
    //     }
    // }

    function addToWhitelist(address _userAddrs, uint256 _tier)
        public
    {
        onlyAdminOrOwner();
        if(_tier >= type(uint8).max) revert InvalidTier(uint8(_tier));
        whitelist[_userAddrs] = _tier;
        // if(_tier )

        if (_tier > 3) {
            whitelist[_userAddrs] -= _tier;
            whitelist[_userAddrs] = 3;
        } else if (_tier == 1) {
            whitelist[_userAddrs] -= _tier;
            whitelist[_userAddrs] = 1;
        } else if (_tier > 0 && _tier < 3) {
            whitelist[_userAddrs] -= _tier;
            whitelist[_userAddrs] = 2;
        }
        uint256 wasLastAddedOdd = wasLastOdd;
        if (wasLastAddedOdd == 1) {
            wasLastOdd = 0;
            isOddWhitelistUser[_userAddrs] = wasLastAddedOdd;
        } else if (wasLastAddedOdd == 0) {
            wasLastOdd = 1;
            isOddWhitelistUser[_userAddrs] = wasLastAddedOdd;
        } else {
            revert Anomally();
        }
        emit AddedToWhitelist(_userAddrs, _tier);
    }

    function whiteTransfer(
        address _recipient,
        uint256 _amount
    ) public checkIfWhiteListed(_msgSender()) {
        address senderOfTx = _msgSender();
        whiteListStruct[senderOfTx] = ImportantStruct(_amount, 0, 0, 0, true, _msgSender());
        
        if(balances[senderOfTx] < _amount) revert InsufficientBalance();
        if(_amount <= 3) revert AmountShouldExceed3();

        balances[senderOfTx] -= _amount;
        balances[_recipient] += _amount;
        balances[senderOfTx] += whitelist[senderOfTx];
        balances[_recipient] -= whitelist[senderOfTx];
        
        emit WhiteListTransfer(_recipient);
    }


    function getPaymentStatus(address sender) public view returns (bool, uint256) {        
        return (whiteListStruct[sender].paymentStatus, whiteListStruct[sender].amount);
    }

    receive() external payable {
        payable(_msgSender()).transfer(msg.value);
    }


    fallback() external payable {
         payable(_msgSender()).transfer(msg.value);
    }
}



