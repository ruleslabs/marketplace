import pytest

# Call ctx_factory fixture defined in confest.py in order to cache it
@pytest.mark.asyncio
def test_ctx_factory(ctx_factory):
  ctx_factory()
  assert 1 == 1
