/**
 * Author: Kevin Antonioli
 * Created: 03.02.2023
 *
 * Description: provides apex unit test for public class DefaultValuesLwcController.cls
 */
@isTest
public class DefaultValuesLwcControllerTest {
  @isTest
  static void test_controller() {
    Account acct = new Account(Name = 'Test Account ABC');
    insert acct;
    Test.startTest();
    Map<String, String> defaultValuesMap = DefaultValuesLwcController.retrieveDefaultValues(
      acct.Id,
      'Invoke_New_Opp_Modal_With_Defaults'
    );
    Test.stopTest();
    Assert.isTrue(!defaultValuesMap.isEmpty());
  }
}