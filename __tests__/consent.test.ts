import { AdsConsent } from '../lib';

describe('Google Ads AdsConsent', function () {
  describe('requestInfoUpdate', function () {
    it('throws if publisherIds is not an array', function () {
      // @ts-ignore
      expect(() => AdsConsent.requestInfoUpdate('pub-123')).toThrowError(
        "AdsConsent.requestInfoUpdate(*) 'publisherIds' expected an array of string values.",
      );
    });

    it('throws if publisherIds is empty array', function () {
      expect(() => AdsConsent.requestInfoUpdate([])).toThrowError(
        "AdsConsent.requestInfoUpdate(*) 'publisherIds' list of publisher IDs cannot be empty.",
      );
    });

    it('throws if publisherIds contains non-string values', function () {
      // @ts-ignore
      expect(() => AdsConsent.requestInfoUpdate(['foo', 123])).toThrowError(
        "AdsConsent.requestInfoUpdate(*) 'publisherIds[1]' expected a string value.",
      );
    });
  });
});
