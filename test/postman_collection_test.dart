import 'package:flutter_test/flutter_test.dart';
import 'package:money_meter_op/models/postman_collection.dart';

void main() {
  group('MyData / PostmanCollection', () {
    test('parses Money Meter collection JSON structure correctly', () {
      const sampleJson = '''
{
  "info": {
    "_postman_id": "47568f93-27c0-45dd-9147-b219571db3b7",
    "name": "Money Meter",
    "schema": "https://schema.getpostman.com/json/collection/v2.1.0/collection.json",
    "_exporter_id": "28214229"
  },
  "item": [
    {
      "name": "member",
      "item": [
        {
          "name": "Income Master",
          "item": [
            {
              "name": "add Income Master",
              "request": {
                "method": "POST",
                "body": {
                  "mode": "formdata",
                  "formdata": [
                    {
                      "key": "fInc_familyId",
                      "value": "1"
                    },
                    {
                      "key": "fInc_sIncName",
                      "value": "Rent Income"
                    }
                  ]
                }
              }
            }
          ]
        }
      ]
    },
    {
      "name": "Member Login",
      "request": {
        "method": "POST",
        "body": {
          "mode": "formdata",
          "formdata": [
            {
              "key": "username",
              "value": "9227219561"
            },
            {
              "key": "password",
              "value": "Deep@123"
            }
          ]
        }
      }
    }
  ]
}
''';

      final myData = MyData.fromJsonString(sampleJson);

      expect(myData.info?.name, 'Money Meter');
      expect(myData.info?.sPostmanId, '47568f93-27c0-45dd-9147-b219571db3b7');
      expect(myData.item, hasLength(2));
      expect(myData.item?.first.name, 'member');
      expect(myData.item?.last.name, 'Member Login');

      final memberItem = myData.item?.first.item?.first.item?.first;
      expect(memberItem?.name, 'add Income Master');
      expect(memberItem?.request?.method, 'POST');
      expect(memberItem?.request?.body?.formdata, hasLength(2));
      expect(memberItem?.request?.body?.formdata?.first.key, 'fInc_familyId');
      expect(memberItem?.request?.body?.formdata?.first.value, '1');
    });

    test('serializes back to JSON correctly', () {
      final myData = MyData(
        info: Info(name: 'Test Collection', schema: 'v2.1'),
        item: [
          Item(
            name: 'Test Request',
            request: Request(
              method: 'GET',
              url: Url(raw: 'https://example.com/api'),
            ),
          ),
        ],
      );

      final jsonMap = myData.toJson();
      expect(jsonMap['info']['name'], 'Test Collection');
      expect(jsonMap['item'][0]['name'], 'Test Request');
      expect(jsonMap['item'][0]['request']['method'], 'GET');
    });
  });
}
